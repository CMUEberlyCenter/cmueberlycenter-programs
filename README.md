# Eberly Programs

Seminar registration, attendance and Future Faculty Program records for the
Eberly Center. The app uses Rails 8.1, Ruby 3.4, SQLite, Hotwire, Propshaft and the
Carnegie Mellon Web Kilt for its look.
The deployment Ruby version is recorded in `.ruby-version`.

## Development

1. Install the Ruby version in `.ruby-version` and run `bundle install`.
2. Run `bin/rails db:prepare demo:seed`, then `bin/rails server`.
3. Open <http://localhost:3000> and choose Sign In.

Development and test sign in through developer sign-in at `/login`: pick a
test account from `config/test_accounts.yml` (Andrew Carnegie is an
administrator, Andrew Mellon a participant). They also look people up in a
made-up directory, `config/demo_directory.yml`, in place of CMU's LDAP
directory. `demo:seed` loads made-up seminars, registrations and Future
Faculty Program records with those people; it runs only in development and
stops on a database with anyone else in it. Mail in development is logged,
never sent.

The seed data (`bin/rails db:seed`, which `db:prepare` runs on a new
database) is safe to run repeatedly and preserves existing records and IDs.
It provides status types and the 2012, 2015 and 2023 program reference data.
`DEFAULT_SEMINAR_TAG` sets the first seminar tag settings, and
`BOOTSTRAP_ADMIN_ANDREWID` makes someone an administrator.

The application keeps Rails 7.0 compatibility defaults. Adopt newer defaults
separately, including any session or cache format changes.

## Containers

The Dockerfile has four targets on the pinned Ruby: `development` (a
devcontainer), `test` (runs every check), `production-build` and
`production` (the published image). In VS Code, choose **Dev Containers:
Reopen in Container**; without it, `docker compose up --build` runs the app
on <http://localhost:3000> (`PORT=3100` for another port). On Linux, if your
UID or GID isn't 1000, export `LOCAL_UID=$(id -u)` and `LOCAL_GID=$(id -g)`
first.

Publish Image runs the checks on every push and pull request, and pushes
`ghcr.io/cmueberlycenter/cmueberlycenter-programs` for each version tag (a
bare number such as 0.1.0) or a manual run.

The image runs as production by default. With `RAILS_ENV=development` it
runs with developer sign-in and the made-up directory, for a demo with
made-up data. Either way the database is a SQLite file in `/app/storage`,
which belongs on a volume, and the app listens on port 3000 (`PORT`). Set:

| Variable | What it does |
| --- | --- |
| `RAILS_ENV` | `production` (the default) or `development` for a demo |
| `SECRET_KEY_BASE` | A long random secret that stays the same between restarts |
| `APP_HOST` | The address the app answers to behind a proxy, such as `programs.eberly.cmu.edu`, in development |
| `LDAP_BIND_DN`, `LDAP_PASSWORD` | CMU LDAP, in production only |

Set up or update the database as a one-off in the running container,
`bin/rails db:prepare`, and for a demo `bin/rails db:prepare demo:seed`.
Migrations never run when the container starts. The proxy in front of the
app sends `X-Forwarded-Proto: https`, or signing in fails. `/up` answers 200
once the database is set up, from any host.

## Checks

```sh
RAILS_ENV=test bin/rails db:prepare
bin/rails test
bin/rails zeitwerk:check
```

`docker build --target test .` runs the same checks in the image.

## Migration Retention

Keep migrations for at least 12 months and until every maintained environment
has applied them. Bootstrap fresh databases from `db/schema.rb` and seed data; `db:prepare`
loads the schema into a database with no tables of its own.

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

Rails encryption keys, `.env` files and plaintext legacy secret files belong
outside Git. LDAP binding uses `LDAP_BIND_DN` and `LDAP_PASSWORD` from
deployment-managed environment variables. Encrypted Rails credentials may be
versioned, but their decryption keys must remain private. Never copy
configuration values or decrypted credentials into logs, issues or commit
messages.

Production has no sign-in yet: `/login` says so. Single sign-on (Entra ID)
goes there next. The nightly `bin/rails cron:nightly_chores` job and an SMTP
relay are the deployment's to provide.
