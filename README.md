# Oban Migrations as SQL

Creates plain Pg/SQL migrations with [Oban] database schema changes.

**Requires Elixir `~> 1.13`.**

Reference: https://github.com/sorentwo/oban/issues/653

## Usage

This script requires `elixir` to be present in your `PATH`. No external libraries are needed.

```sh
./oban_migrations_sql.exs
  # Postgres schema where Oban will reside. You must use snake_case here.
  [--prefix PREFIX=public]

  # Directory where you want to put generated migrations.
  [--out PATH=./out]

  # Oban migrations versions to apply. Defaults to all versions.
  [--from FROM=1]
  [--to TO]        # if omitted, defaults to latest

  # Should generated migrations manage Postgres schema "prefix"?
  [--create_schema BOOLEAN=true]
```

**Disclaimer:** Author of this script didn't bother with input validation so pay attention to what
you are doing.

This script creates a new migration in output directory. Please review changes, commit them to your
migrations repository and execute with your migrations runner.

## Output format

Generated migrations should be consumable by many migrations systems out of the box. If your use
case requires some manual modifications, do not hesitate to open an issue and we may consider
adding support for various output formats.

Long story short, this is what you get after running this script:

```sh
$ ./oban_migrations_sql.exs --prefix public
$ tree out
out
└── 1647007095259_public_oban_v01_to_v11
    ├── down.sql
    └── up.sql

1 directory, 2 files
```

Oban migrations range is concatenated into single migration file, together with some Oban metadata
update queries.

## License

See the [LICENSE](./LICENSE.txt) and [NOTICE](./NOTICE) files for license rights and limitations.

[Oban]: https://getoban.pro/
