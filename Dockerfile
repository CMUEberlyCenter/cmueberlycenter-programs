# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.4.12
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl libsqlite3-0 sqlite3 libyaml-0-2 tzdata \
    && rm -rf /var/lib/apt/lists/*
RUN gem install bundler -v 2.6.9 --no-document
ENV BUNDLE_PATH=/usr/local/bundle

FROM base AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git libsqlite3-dev libyaml-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock .ruby-version ./

# Development: a devcontainer with the source mounted at /app
FROM build AS development
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid ${USER_GID} vscode \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash vscode
RUN bundle install && chown -R vscode:vscode /usr/local/bundle /app
USER vscode
EXPOSE 3000
CMD ["sleep", "infinity"]

# Every check: the tests and the eager-load check, on SQLite
FROM build AS test
ENV RAILS_ENV=test
RUN bundle install
COPY . .
RUN bin/rails db:prepare && bin/rails test && bin/rails zeitwerk:check

# The published image: development and production gems, assets compiled
FROM build AS production-build
ENV RAILS_ENV=production BUNDLE_WITHOUT=test BUNDLE_FROZEN=true
RUN bundle install && rm -rf /usr/local/bundle/ruby/*/cache
COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

# Runs as production by default; RAILS_ENV=development runs it with
# developer sign-in and made-up people. The database lives in /app/storage.
FROM base AS production
ENV RAILS_ENV=production BUNDLE_WITHOUT=test BUNDLE_FROZEN=true \
    RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1 PIDFILE=/tmp/programs-server.pid
RUN groupadd --gid 1000 rails \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash rails
COPY --from=production-build /usr/local/bundle /usr/local/bundle
COPY --from=production-build --chown=rails:rails /app /app
RUN mkdir -p /app/storage /app/tmp /app/log && chown -R rails:rails /app/storage /app/tmp /app/log
USER rails
VOLUME /app/storage
ENTRYPOINT ["/app/docker/entrypoint"]
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s CMD curl -fsS http://localhost:3000/up || exit 1
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
