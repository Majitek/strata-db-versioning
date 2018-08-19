# [Urbanise Strata](https://urbanise.com/platform/strata-management/) database versioning tool
Urbanise way for updating and versioning database instances used for Strata Management Platform

## Contents

- [Quick Start](#quick-start)
- [How it works](#how-it-works)
    - [Prerequisites](#prerequisites)
    - [Options](#options)
- [Contributing](#contributing)
    - [Contributors](#contributors)
    - [How to contribute](#how-to-contribute)
- [License](#license)

## Quick Start

Read this great article from [Petromir Dzhunev](https://twitter.com/dzhunev) 

## How it works

We use [Flyway](https://flywaydb.org/) and Bash for updating and versioning our PostgreSQL RDS instances.

### Prerequisites

1. Install [Docker Compose](https://docs.docker.com/compose/install/)
2. Install PostgreSQL client ([psql](https://www.postgresql.org/docs/current/static/app-psql.html))
    - [macOS](https://stackoverflow.com/a/46703723)
    - Amazon Linux Image (AMI) - `sudo yum install postgresql96 -y`
    
### Options

|Option|Meaning|Desription|
|------|-------|----------|
| `-h` | Help | Prints all options |
| `-d` | URL | Sets database URL. Expected format is <host>:<port>/<db> (*required*). |
| `-u` | Username | Sets database username. |
| `-p` | Password | Sets database password. |
| `-s` | Schema | Sets database schema. This can be comma separated list |
| `-f` | SQL scripts folder | Sets the folder where sql scripts are placed. Note that the script directory is used as root. |
| `-r` | Rollback | Executes rollback scripts defined in <sql_folder>. |
| `-i` | Ignore | Ignores hot-fix scripts. |
    
## Running

## Contributing

### Contributors

Main contributor is [Petromir Dzhunev](https://bg.linkedin.com/in/pdzhunev) 

### How to contribute

Simply fork repository, make changes and create a pull request. We will review your changes and apply them to the `master` branch shortly.
Another option is to open an issue.

## License

[MIT](LICENSE)
