source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
ruby '2.2.0'
gem 'rails', '~> 4.2.0'
# Use sqlite3 as the database for Active Record
# Use SCSS for stylesheets
# gem 'sass-rails', '~> 5.0.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .js.coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# gem 'therubyracer',  platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
# gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.1', group: :doc
gem 'pg'
gem 'simple_form', '~> 3.1.0'
# gem 'slim-rails', '~> 3.0.1'
gem 'slim-rails', github: 'ericboehs/slim-rails'
gem 'unicorn'
gem 'unicorn-rails'
gem 'foundation-rails', '5.4.5'
gem 'foundation-icons-sass-rails', '~> 3.0.0'
gem 'devise', '~> 3.4.0'
gem 'omniauth-facebook', '~> 2.0.0'
gem 'koala', '~> 1.11'
gem 'font-awesome-rails', '~> 4.2.0.0'
gem 'meta-tags', '~> 2.0'

# problems with rails 4.2 asset pipline had to do this:
# https://github.com/Compass/compass-rails/issues/155#issuecomment-68007028
gem 'compass-rails', '~> 2.0.0'
gem 'sprockets-rails', '2.2.2'
gem 'sprockets', '2.11.3'
gem 'sass-rails', '~> 4.0.5'
gem 'sass', '3.2.19'
gem 'wicked', '~> 1.1.1'
gem 'carrierwave', '~> 0.10.0'
gem 'fog', '~> 1.27.0'
gem 'mini_magick', '~> 3.8.0'
gem 'aasm', '~> 3.4.0'
gem 'pundit', '~> 0.3.0'
gem 'active_link_to'
gem 'airbrake', '~> 4.0.0'
gem 'sunspot_rails', '~> 2.1.1'
gem 'kaminari', '~> 0.16.1'
gem 'video_info', '~> 2.3.1'
gem 'public_suffix', '~> 1.4.5'
gem 'public_activity', '~> 1.4'
gem 'rails_autolink', '~> 1.1.6'
gem 'rolify', '~> 3.4.1'
gem 'reform', '~> 1.2.4'
# gem 'reform', '~> 1.1.1' #1.2.2
gem 'acts_as_votable', '~> 0.10.0'
gem 'sidekiq', '~> 3.2.6'
gem 'sinatra', '>= 1.3.0', :require => nil
gem 'foundation-datetimepicker-rails'
gem 'foundation_datepicker_rails', '~> 0.0.2'
gem 'chosen-rails', '~> 1.2.0'
gem 'ledermann-rails-settings', '~> 2.3'
gem 'show_me_the_cookies'
gem "box-view-ruby", :git => "https://github.com/makaio/box-view-ruby.git"
gem 'rest-client', '~> 1.7'
gem 'skylight', '~> 0.6'
gem 'mechanize', '~> 2.7'
gem 'copy_carrierwave_file', '~> 1.1'
gem 'geocoder', '~> 1.2'
gem 'tweet-button', '~> 0.1'
gem 'unscoped_associations'

group :development do
  gem 'spring'
  gem 'rails_layout'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'quiet_assets'
  gem 'terminal-notifier-guard'
  gem 'sunspot_solr'
  gem 'progress_bar'
  gem 'foreman'
end

group :production, :staging do
  gem 'rails_12factor'
  gem 'heroku-deflater'
end

group :development, :test do
  gem 'dotenv-rails'
  gem "capybara-webkit"
  gem 'shoulda-matchers', '~> 2.6.1', require: false
  gem 'capybara', '~> 2.4.4'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'pry-rails', '~> 0.3.0'
  gem 'launchy'
  gem 'spring-commands-rspec'
  gem 'rspec-rails', '~> 3.1.0'
  gem 'guard-rspec', '~> 4.3.1', require: false
end

group :test, :darwin do
  gem 'rb-fsevent'
end

group :test do
  gem "sunspot_test"
end
