FROM ruby:3.1.2-slim


WORKDIR /

RUN apt update
RUN apt install build-essential -y 
RUN gem install bundler

COPY Gemfile .
COPY Gemfile.lock . 

RUN bundle install

COPY . .