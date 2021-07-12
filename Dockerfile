FROM ruby:2.7-slim

LABEL NAME=branch-protection-enforcer-app

EXPOSE 3000

WORKDIR /app

COPY . /app

RUN bundle config --global frozen 1 && \
    bundle config --local deployment true && \
    bundle config --local without development test && \
    bundle install

CMD ["bundle", "exec", "ruby", "server.rb"]
