# [Urbanise Strata](https://urbanise.com/platform/strata-management/) database versioning tool
Urbanise way for updating and versioning database instances used for Strata Management Platform

## Contents

- [Quick Start](#quick-start)
- [How it works](#how-it-works)
    - [Prerequisites](#prerequisites)
    - [Options](#options)
    - [Running](#running)
    - [Implementation Details](#implementation-details)
- [Contributing](#contributing)
    - [Contributors](#contributors)
    - [How to contribute](#how-to-contribute)
- [License](#license)

## Quick Start

Read this great [article](https://medium.com/@pdzhunev/database-versioning-with-flyway-and-bash-b5e747685799) from [Petromir Dzhunev](https://twitter.com/dzhunev).

## How it works

We use [Flyway](https://flywaydb.org/) and Bash for updating and versioning our PostgreSQL RDS instances.

### Prerequisites

1. Install [Docker Compose](https://docs.docker.com/compose/install/)
2. Install PostgreSQL client ([psql](https://www.postgresql.org/docs/current/static/app-psql.html))
    - [macOS](https://stackoverflow.com/a/46703723)
    - Amazon Linux Image (AMI) - `sudo yum install postgresql96 -y`
    
### Options

|Option|Meaning|Desription|Required| 
|------|-------|----------|--------|
| `-d` | URL | Sets database URL. Expected format is `<host>:<port>/<db>` | Yes |
| `-u` | Username | Sets database username. | Yes |
| `-p` | Password | Sets database password. | Yes |
| `-s` | Schema | Sets database schema. | Yes |
| `-f` | SQL scripts folder | Sets the folder where sql scripts are placed. Note that the script directory is used as root. | Yes |
| `-r` | Rollback | Executes rollback scripts defined in <sql_folder>. | No |
| `-i` | Ignore | Ignores hot-fix scripts. | No |
| `-h` | Help | Prints all options | No |
    
### Running

1. Check out the project.
   
   		git clone https://github.com/Majitek/strata-db-versioning.git	
   		cd strata-db-versioning

2. Run local PostgreSQL server.

		docker-compose up -d
		
3. Use one of these commands depending on specific case. Each of them relies on:
			
		SQL_FOLDER=$(find * -type d -name "sprint*" | sort | tail -n 1)
	
	* Incremental versioning.
			
			./update_db.sh -d localhost/test -u test -p test -s public -f $SQL_FOLDER
			
	* Undo previously applied versions.
	
			./update_db.sh -d localhost/test -u test -p test -s public -f $SQL_FOLDER -r
			
	* Ignoring hot-fixes.
	
			./update_db.sh -d localhost/test -u test -p test -s public -f $SQL_FOLDER -i

### Implementation details

1. The bash script is compatible with GNU and BSD.
2. Undo functionality executes all `.rollback` scripts, so for now there is no option to revert only single change.
3. No file prefix option is provided yet, so script change is required to add yours.
4. History table is named `schema_history`, instead of `flyway_schema_history`.
5. `--net=host` is used as a parameter to Docker run command, which allows accessing local PostgreSQL server.
6. Depending on your Docker system configuration, you may be required to preface the `docker run` command with `sudo`. To avoid having to use `sudo` with the `docker` command, your system administrator can create a Unix group called `docker` and add users to it.

## Contributing

### Contributors

Main contributor is [Petromir Dzhunev](https://bg.linkedin.com/in/pdzhunev).

### How to contribute

Simply fork repository, make changes and create a pull request. We will review your changes and apply them to the `master` branch shortly.
Another option is to open an issue.

## License

[MIT](LICENSE)
