source :rubygems

gem 'rake', '>= 0.8.7', :require => false
gem 'activesupport', '>= 2.3.0', :require => false

group :development do
  gem 'jeweler', '~> 1.8.4', :require => false
  platforms :ruby do
    gem 'yard', :require => false
  end
end

group :development, :test do
  gem 'rspec', :require => false
  platforms :ruby do
    gem 'pry', :require => false
    gem 'pry-coolline', :require => false
  end
end

group :test do
  gem 'wrong', '>=0.6.2', :require => false
  gem 'files', '>=0.2.1', :require => false
end
