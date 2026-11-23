# Eberly Programs

Seminar registration, attendance and Future Faculty Program records for the
Eberly Center. The app uses Rails 8.1, Ruby 3.4, MySQL, Hotwire and Propshaft.
The deployment Ruby version is recorded in `.ruby-version`.

## Containers

The Dockerfile provides `development` and `production` targets using the pinned
Ruby version. No host Ruby, Node or MySQL installation is needed for containers;
JavaScript uses import maps. Docker Compose supplies MySQL 8.0 and Redis locally.

In VS Code, choose **Dev Containers: Reopen in Container**. Setup installs the
bundle and prepares separate development and test databases. Start Rails in
the container terminal:

```sh
bin/rails server -b 0.0.0.0
```

Without VS Code:

```sh
docker compose up --build
docker compose run --rm rails sh -c 'RAILS_ENV=test bin/rails db:prepare && bin/rails test'
docker compose exec rails bin/rails console
```

Open <http://localhost:3000>. On Linux, if your UID/GID differ from 1000, export
`LOCAL_UID=$(id -u)` and `LOCAL_GID=$(id -g)` before building with Compose.
If port 3000 is occupied, use `PORT=3100 docker compose up` and open port 3100.
The devcontainer adjusts the editor user's UID automatically. Rebuild after
changing the Gemfile or lockfile. Source changes reload from the mounted checkout.
Compose mounts the database example over `config/database.yml` inside the
container, preserving any existing host configuration and encryption keys.

MySQL data lives in a named volume. `docker compose down` preserves it;
`docker compose down --volumes` deletes the development databases. The fixed
database passwords in Compose are for this isolated local environment. Only
Rails is published, on loopback; MySQL and Redis have no host ports.

Public pages and tests work without CMU credentials. Login and directory-backed
participant creation still require CMU LDAP access. Export `LDAP_BIND_DN`,
`LDAP_PASSWORD` and, for local login, `REMOTE_USER=your-andrewid` before starting
Compose. Administrator provisioning remains explicit through the seed command
described below. Development mail uses Rails' default SMTP delivery configuration;
no mail catcher is included.

The production image contains the runtime bundle and precompiled assets and
runs as a non-root user. Local environment files, keys, database dumps, cached
gems and generated assets are excluded from the build context. Build and check
it without supplying production credentials:

```sh
docker build --target production -t seminars:local .
```

An optional deployment Compose file uses externally managed MySQL and Redis.
Export `DATABASE_URL`, `REDIS_URL` and a persistent `SECRET_KEY_BASE`; provide
`RAILS_MASTER_KEY` if encrypted credentials are needed. For an existing site,
retain its actual Rails secret to preserve sessions. Supply LDAP variables at
runtime as needed. Then:

```sh
docker compose -f docker/production/compose.yml build
docker compose -f docker/production/compose.yml run --rm rails bin/rails db:migrate
docker compose -f docker/production/compose.yml up -d
```

For a new database, use `db:prepare` instead of `db:migrate`. Migrations never
run automatically on production container startup. Uploaded files persist in
the production storage volume. The web port binds to loopback for a host reverse
proxy. Deployment still needs the site's trusted Shibboleth identity integration
to populate `request.env['REMOTE_USER']`, SMTP relay access and the nightly
`bin/rails cron:nightly_chores` job; the container does not configure these services.

GitHub Actions builds both image targets and runs the Rails suite against MySQL.
It does not publish images or deploy the app.

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
