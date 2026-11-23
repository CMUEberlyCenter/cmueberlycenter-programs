# syntax=docker/dockerfile:1
ARG RUBY_VERSION=3.4.12
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl libmariadb3 libsqlite3-0 libyaml-0-2 tzdata \
    && rm -rf /var/lib/apt/lists/*
RUN gem install bundler -v 2.6.9 --no-document
ENV BUNDLE_PATH=/usr/local/bundle

FROM base AS build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git libmariadb-dev libsqlite3-dev libyaml-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock .ruby-version ./

FROM build AS development
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid ${USER_GID} vscode \
    && useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash vscode
RUN bundle install && chown -R vscode:vscode /usr/local/bundle /app
USER vscode
EXPOSE 3000
CMD ["sleep", "infinity"]

FROM build AS production-build
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test BUNDLE_FROZEN=true
RUN bundle install && rm -rf /usr/local/bundle/ruby/*/cache
COPY . .
COPY config/database.yml.example config/database.yml
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

FROM base AS production
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test BUNDLE_FROZEN=true \
    RAILS_LOG_TO_STDOUT=1 RAILS_SERVE_STATIC_FILES=1 PIDFILE=/tmp/seminars-server.pid
RUN groupadd --gid 1000 rails \
    && useradd --uid 1000 --gid 1000 --create-home --shell /bin/bash rails
COPY --from=production-build /usr/local/bundle /usr/local/bundle
COPY --from=production-build --chown=rails:rails /app /app
RUN mkdir -p /app/storage /app/tmp /app/log && chown -R rails:rails /app/storage /app/tmp /app/log
USER rails
ENTRYPOINT ["/app/docker/entrypoint"]
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
