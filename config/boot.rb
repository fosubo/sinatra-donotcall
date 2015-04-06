require "bundler"
require 'active_record'

ENV['RACK_ENV'] = ENV['RAILS_ENV'] if ENV['RACK_ENV'].to_s.empty?

Bundler.setup
Bundler.require(:default, :console, ENV.fetch("RACK_ENV", :development))

UPLOAD_PATH = './uploads/'
if !File.directory?(UPLOAD_PATH)
  `mkdir #{UPLOAD_PATH}`
end

spec = ENV['DATABASE_URL'] || "postgresql://localhost:5432/donotcall"

ActiveRecord::Base.establish_connection(spec)
