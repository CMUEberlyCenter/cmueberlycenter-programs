# Eberly Programs

Seminar registration, attendance and Future Faculty Program records for the
Eberly Center. The app uses Rails 8.1, Ruby 3.4, MySQL, Hotwire and Propshaft.
The deployment Ruby version is recorded in `.ruby-version`.

## Development

1. Install the Ruby version in `.ruby-version` and MySQL development headers.
2. Run `bundle install`.
3. Copy `config/database.yml.example` to `config/database.yml` and configure
   the database using environment variables. Development and test must use
   separate databases from production.
4. Provide `RAILS_MASTER_KEY` or a local `config/master.key` when using the
   encrypted credentials. Alternatively, provide `SECRET_KEY_BASE` in production.
5. Run `bin/rails db:prepare`, then `bin/rails server`.

The seed data is safe to run repeatedly and preserves existing records and IDs.
It provides status types and the 2012, 2015 and 2023 program reference data.
`DEFAULT_SEMINAR_TAG` controls the initial seminar tag settings. To provision
an administrator, explicitly set `BOOTSTRAP_ADMIN_ANDREWID` when running
`bin/rails db:seed`; this requires access to CMU LDAP. Default seeds do not
create personal accounts or contact LDAP.

The application retains Rails 7.0 compatibility defaults while the framework
upgrade is validated. Adopt newer defaults separately, including any session
or cache format changes.

## Checks

With a separate test database configured:

```sh
RAILS_ENV=test bin/rails db:prepare
bin/rails test
bin/rails zeitwerk:check
```

MySQL is the production database. SQLite may be used for isolated tests with
`DATABASE_URL`, but MySQL-specific schema options require an adapted test
schema; SQLite checks do not replace MySQL validation.

## Migration Retention

Keep migrations for at least 12 months and until every maintained environment
has applied them. Bootstrap fresh databases from `db/schema.rb` and seed data.

Before retiring migrations:

1. Record all existing migration files and the current schema in Git history.
2. Run `bin/rails db:migrations:retirement_report` in every maintained environment
   and confirm the candidate migrations are applied.
3. Verify the schema matches production and that loading the schema and running
   seeds can create a working disposable database.
4. Check that supported rollback and upgrade paths no longer need those files.
5. Retire the files in a dedicated commit. Keep newer migrations in `db/migrate`.

Do not renumber applied migrations, alter historical migration contents, or
clear production's `schema_migrations` table. Git retains the retired history.
Migrations are currently retained pending production verification and the
migration-history catch-up commit.

## Configuration and Deployment

Database passwords, Rails encryption keys, `.env` files and plaintext legacy
secret files belong outside Git. LDAP binding uses `LDAP_BIND_DN` and
`LDAP_PASSWORD` from deployment-managed environment variables.
Encrypted Rails credentials may be versioned, but their decryption keys must
remain private. Never copy configuration values or decrypted credentials into
logs, issues or commit messages.

Run the app with Puma using `bundle exec puma -C config/puma.rb`. The repository
no longer uses Capistrano. Preserve the existing server's reverse proxy,
Shibboleth authentication and scheduled jobs when deploying; replacing those
services is outside the framework upgrade.

For an existing installation, install the pinned Ruby and bundle first, run
`bin/rails db:migrate`, precompile assets and restart the existing app service.
The new migration removes only duplicate participant foreign keys with
identical rules. It preserves one constraint and leaves constraints with
different columns or actions intact. Existing program data is not rewritten.
