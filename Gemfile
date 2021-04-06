# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.5'

gem 'rails', '~> 6.1.3', '>= 6.1.3.1'
gem 'puma', '~> 5.2'
gem 'jbuilder', '~> 2.7'

gem "lograge", "~> 0.11"
gem "health_check", "~> 3.0"

group :development, :test do
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
end

group :development do
  gem "pdf-reader", "~> 2.4.2"
end
