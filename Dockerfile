FROM ruby:2.6.2-alpine

RUN apt-get update -qq && \
    apt-get install -y \
        build-essential \
        libpq-dev \
        nodejs \
        rsync && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apk add --no-cache curl postgresql-dev tzdata git make gcc g++ python linux-headers binutils-gold gnupg libstdc++ yarn

ARG env=development

WORKDIR /app
COPY /app /app/app
COPY /bin /app/bin
COPY /config /app/config
COPY /db /app/db
COPY /lib /app/lib
COPY /public /app/public
COPY /spec /app/spec
COPY /config.ru /app/
COPY /Gemfile /app/
COPY /Gemfile.lock /app/
COPY /Rakefile /app/
COPY /gen-sitemaps-and-run.sh /app/gen-sitemaps-and-run.sh
# files could be mounted in dev for realtime code changes without rebuild
# typically that would be: .:/app

# copy build cache for the requested environment only
COPY /build-cache/$env/bundle/ /usr/local/bundle/

RUN mkdir /var/www && \
    chown -R www-data /app /var/www /usr/local/bundle

USER www-data

# install a matching bundler to Gemfile.lock
RUN gem install bundler -v 2.0.1

# install all gems
ARG env=development
ARG bundle_opts=

ENV RAILS_ENV $env
ENV RACK_ENV $env



RUN echo "Running \"bundle install $bundle_opts\" with environment set to \"$env\"..." && \
    bundle install $bundle_opts

RUN echo "Installing Yarn" && \
    yarn install

RUN echo "Compiling assets" && \
    bundle exec rails assets:precompile

EXPOSE 3000

ENTRYPOINT ["bundle", "exec"]
CMD ["./gen-sitemaps-and-run.sh"]
