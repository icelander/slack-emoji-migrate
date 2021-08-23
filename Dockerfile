FROM ruby:3.0.1

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile* ./
RUN bundle install

ADD lib ./lib
COPY main.rb .
COPY entrypoint.sh .

VOLUME ["/usr/src/app/output"]

CMD ["./entrypoint.sh"]