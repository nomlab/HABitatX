# syntax = docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version and Gemfile
ARG RUBY_VERSION=3.3.3
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim as base

# Rails app lives here
RUN mkdir /home/habitatx
WORKDIR /home/habitatx

# Set environment (can be overridden)
ARG RAILS_ENV=production
ENV RAILS_ENV=${RAILS_ENV} \
    BUNDLE_PATH="/usr/local/bundle"

# Throw-away build stage to reduce size of final image
#FROM base as build

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libvips pkg-config

# Install packages needed for deployment, including vim
RUN apt-get install --no-install-recommends -y curl libsqlite3-0 libvips sudo vim locales && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Create habitatx user with sudo privileges
ARG UID
RUN useradd -s /bin/bash -u $UID habitatx && \
    usermod -aG sudo habitatx && \
    sed -i 's/^%sudo.*$/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

# Set locale
RUN locale-gen ja_JP.UTF-8
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_TIME C
ENV TZ Asia/Tokyo
RUN localedef -f UTF-8 -i ja_JP ja_JP.utf8

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Ensure vendor/javascript directory exists
RUN mkdir -p vendor/javascript

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production (only if production)
RUN if [ "$RAILS_ENV" = "production" ]; then \
      SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile; \
    fi

# Final stage for app image
#FROM base


# Copy built artifacts: gems, application
#COPY --from=build /usr/local/bundle /usr/local/bundle
#COPY --from=build . /home/habitatx
#COPY /usr/local/bundle /usr/local/bundle
COPY . /home/habitatx

# Run and own only the runtime files as a non-root user for security
RUN chown -R habitatx:habitatx /home/habitatx
USER habitatx:habitatx

# Entrypoint prepares the database.
ENTRYPOINT ["/home/habitatx/bin/docker-entrypoint"]

# Start the server by default, this can be overwritten at runtime
EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]