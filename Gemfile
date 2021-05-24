# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.0.1"

gem "rails", "~> 6.1.3", ">= 6.1.3.1"
gem "puma", "~> 5.3"
gem "jbuilder", "~> 2.7"

gem "sass-rails", "~> 6.0"

gem "lograge", "~> 0.11"
gem "health_check", "~> 3.0"

group :development, :test do
  gem "byebug", "~> 11.1", platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem "pdf-reader", "~> 2.4.2"
  gem "listen", "~> 3.5"
  gem "web-console", "~> 4.1.0"
end
