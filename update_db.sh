#!/bin/bash

#title           :update_db.sh
#description     :Update script for Strata databases
#author          :Petromir Dzhunev
#date            :16 July 2018

# Treat unset variables and parameters other than the special parameters ‘@’ or ‘*’ as an
# error when performing parameter expansion.
set -o nounset

# Exit if command returns non-zero status.
set -o errexit

# The return value of a pipeline is the value of the last (rightmost) command to exit with a
# non-zero status or zero if all commands in the pipeline exit successfully.
set -o pipefail

FLYWAY_DOCKER_IMAGE=boxfuse/flyway:5.1.4-alpine
SQL_FILE_NAME_PREFIX=TEST
SQL_FILE_NAME_PATTERN="$SQL_FILE_NAME_PREFIX-<story_number>-<description_with_underscore_between_words>.<sql|rollback|hotfix>"

enforce_mandatory_options() {
  # Checks for missing required options.
  local missing_options=""

  for opt in "${REQUIRED_OPTIONS[@]}";
  do
    local key=${opt%%:*}
    local value=${opt#*:}

    if [[ "$value" == 0 ]]; then
        missing_options+="-$key "
    fi
  done

  if [[ -n "$missing_options" ]]; then
    log -e "Missing required options: $missing_options.\\nRefer to -h for more info."
    return 1
  fi
}

enforce_file_name_patterns() {
	# Checks if the script file names match the SQL_FILE_NAME_PATTERN and throws an error when invalid is found.
	local invalid_sql_files=$(find ./"$SQL_FOLDER" -type f | grep -vE ".*/TEST-[0-9]+-([a-z0-9]+_?)+\.
	(sql|rollback|hotfix)$")

	if [[ -n "$invalid_sql_files" ]]; then
    local formatted_file_names=$(echo "$invalid_sql_files" | tr ' ' '\n')
    log -e "The following files name don't match '$SQL_FILE_NAME_PATTERN' pattern: \\n$formatted_file_names"
    exit 2
  fi
}

log() {
	local level="[INFO] "
	if [[ "$1" == "e" ]]; then
		level="[ERROR] "
	fi
	echo -e "$level $2"
}

deploy_db_changes() {
	local script_file_extensions=sql
	if "$APPLY_HOT_FIXES"; then
		script_file_extensions+=,hotfix
	else
		generate_schema_history
	fi

	run_flyway_migration "$script_file_extensions"
}

generate_schema_history() {
	# Generated hot-fix history keeps the same versions in all environments even if hot-fix scripts are not actually
	# executed
	declare -a hotfix_versions=($(find ./"$SQL_FOLDER" -name "*.hotfix" -type f | cut -d '-' -f 2))
	local insert_batch_script=""

	for version in "${hotfix_versions[@]}"; do
		insert_batch_script+="insert into \"$SCHEMA\".schema_history(installed_rank, version, description, type, script,
		installed_by, execution_time, success) select max(installed_rank) + 1, '$version', 'Hotfix version generation',
		'SQL', 'N/A', '$USERNAME', 0, true from schema_history;"
	done

	log -i "Generating schema history"

	psql_execute_script "$insert_batch_script"
}

run_flyway_migration() {
	log -i "Running Flyway migration using files with extensions '$1' and script folder $(pwd)/$SQL_FOLDER"
	docker run --net=host -v $(pwd)/"$SQL_FOLDER":/flyway/sql "$FLYWAY_DOCKER_IMAGE" -url="$URL" \
		-schemas="$SCHEMA" -user="$USERNAME" -password="$PASSWORD" -table=schema_history \
		-baselineOnMigrate=true -baselineVersion=0 -ignoreMissingMigrations=true -outOfOrder=true \
		-sqlMigrationPrefix="$SQL_FILE_NAME_PREFIX-" -sqlMigrationSeparator=- -sqlMigrationSuffixes="$1" -group=true migrate
}

delete_schema_history() {
	declare -a versions=( $(find ./"$SQL_FOLDER" -name "*.$1" -type f | cut -d '-' -f 2) )
	if [[ -n "${versions:-}" ]]; then
		local quoted_versions_list=$(printf "'%s'," "${versions[@]}")
		# Use string length to support older version of bash
		quoted_versions_list="${quoted_versions_list:0:${#quoted_versions_list}-1}"

		log i "Deleting schema history with versions $quoted_versions_list"

		psql_execute_script "delete from \"$SCHEMA\".schema_history where version in($quoted_versions_list);"
	fi
}

psql_execute_script() {
	log -i "Executing script using psql"

  # -a Echo all input from script
  # -w Never prompt for password. Allows inline password provisioning.
  # -X Ignore ~/.psqlrc
	PGPASSWORD="$PASSWORD" psql -X -w -h "$HOST" -p "$PORT" -d "$DATABASE" -U "$USERNAME" -c "$1" -a -v ON_ERROR_STOP=on
}

rollback_changes() {
	delete_schema_history sql
	delete_schema_history hotfix

	run_flyway_migration rollback

	delete_schema_history rollback
}

print_version_state() {
	log i "Printing '$SCHEMA' schema status"
	docker run --net=host "$FLYWAY_DOCKER_IMAGE" -url="$URL" -schemas="$SCHEMA" -user="$USERNAME" -password="$PASSWORD" \
		-table=schema_history info
}

usage() {
  local help=$(cat << EOF
  Tool for updating database.
     Usage:
        -h
            Shows this menu.
        -d <url>
            Sets database URL. Expected format is <host>:<port>/<db> (required).
        -u <username>
            Sets database username.
        -p <password>
            Sets database password.
        -s <schema>
            Sets database schema.
        -f <sql_folder>
            Sets the folder where sql scripts are placed. Note that the script directory is used as root.
        -r Executes rollback scripts defined in <sql_folder>.
        -i Ignores hot-fix scripts.
EOF
)
    echo -e "$help"
}

execute() {
	enforce_mandatory_options
	enforce_file_name_patterns

	if "$ROLLBACK"; then
		rollback_changes
	else
		deploy_db_changes
	fi

	print_version_state
}

URL=""
HOST=""
PORT=""
DATABASE=""
SCHEMA=""
SQL_FOLDER=""
USERNAME=""
PASSWORD=""
APPLY_HOT_FIXES=true
ROLLBACK=false
# If no arguments are passed show help.
if [[ $# -eq 0 ]]; then
    usage
    exit 0
else
  OPTSPEC="hird:u:p:f:s:"
  REQUIRED_OPTIONS=('d:0' 'u:0' 'p:0' 's:0' 'f:0')

  while getopts "$OPTSPEC" opt; do
    case "$opt" in
	    d)
        URL="jdbc:postgresql://$OPTARG"
        DATABASE=${OPTARG#*/}
        HOST_PORT=${OPTARG/\/*/}
				HOST=${HOST_PORT%:*}
        PORT=${HOST_PORT#*:}
        REQUIRED_OPTIONS[0]=${REQUIRED_OPTIONS[0]/0/1}
        ;;
	    u)
        USERNAME=$OPTARG
        REQUIRED_OPTIONS[1]=${REQUIRED_OPTIONS[1]/0/1}
        ;;
	    p)
        PASSWORD=$OPTARG
        REQUIRED_OPTIONS[2]=${REQUIRED_OPTIONS[2]/0/1}
        ;;
	    s)
        SCHEMA=$OPTARG
        REQUIRED_OPTIONS[3]=${REQUIRED_OPTIONS[3]/0/1}
        ;;
	    f)
        SQL_FOLDER=$OPTARG
        REQUIRED_OPTIONS[4]=${REQUIRED_OPTIONS[4]/0/1}
        ;;
	    r)
        ROLLBACK=true
        ;;
      i)
        APPLY_HOT_FIXES=false
        ;;
	    h)
        usage
        exit 0
        ;;
	    \?)
        exit 2
        ;;
    esac
  done
fi

# Entry point of script
execute