# syntax=docker/dockerfile:1
FROM ruby:3.1.3
RUN apt-get update -qq && apt-get install -y postgresql-client telnet
WORKDIR /pokemon
COPY Gemfile /pokemon/Gemfile
COPY Gemfile.lock /pokemon/Gemfile.lock
RUN bundle install

# Add a script to be executed every time the container starts.
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3001

# DB creation
CMD ["bundle", "exec", "rake", "db:create"]
RUN ["bundle", "exec", "rails", "db:seed"]

# Configure the main process to run when running the image
CMD ["rails", "server", "-b", "0.0.0.0"]
