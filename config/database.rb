require 'dynamoid'

Dynamoid.configure do |config|
  config.adapter = 'aws_sdk_v2'
  config.namespace = 'bnext_api'
  config.warn_on_scan = false
  config.read_capacity = 3
  config.write_capacity = 3
end
