ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'vcr'
require 'webmock/minitest'

Dir.glob('./{config,models,services,controllers}/init.rb').each { |file| require file }

include Rack::Test::Methods

def app
  BnextDynamo
end

def random_str(n)
  srand(n)
  (0..n).map { ('a'..'z').to_a[rand(26)] }.join
end

VCR.configure do |config|
  config.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  config.hook_into :webmock
end
