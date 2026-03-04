# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 2.4.0'

gem 'activerecord', '>= 4.2.5', '< 9', require: false
gem 'rake', require: false

group :development do
  gem 'bump'
  gem 'mg', require: false
  platforms :mri, :mingw do # N.B. Using mingw for testing against older Rubies!
    gem 'yard', require: false
  end
end

group :development, :test do
  gem 'byebug'
  gem 'guard-rspec', require: false
  gem 'rspec', require: false

  gem 'rubocop', '~> 1.85.0', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', '~> 3.9.0', require: false
  gem 'simplecov', require: false
  gem 'terminal-notifier-guard', require: false

  gem 'codeclimate-test-reporter'
  gem 'coveralls'

  gem 'overcommit'

  platforms :mri, :mingw do # N.B. Using mingw for testing against older Rubies!
    gem 'pry', require: false
    gem 'pry-byebug', require: false
  end
end

group :test do
  gem 'git', require: false
end
