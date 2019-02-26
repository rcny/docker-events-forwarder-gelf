FROM ruby:2.6-alpine
RUN apk add --no-cache --update shadow dumb-init gcc libc-dev make

WORKDIR /app
COPY Gemfile Gemfile.lock .ruby-version ./
RUN bundle install && apk del gcc libc-dev make
COPY . .

CMD [ "dumb-init", "ruby", "main.rb" ]
