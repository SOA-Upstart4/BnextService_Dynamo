require 'sinatra/base'
require 'active_support'
require 'active_support/core_ext'

require 'config_env'
require 'aws-sdk'

class BnextDynamo < Sinatra::Base
  configure do
    set :session_secret, 'something'
    set :api_ver, 'api/v1'
  end

  configure :development, :test do
    ConfigEnv.path_to_config("#{__dir__}/../config/config_env.rb")
    set :api_server, 'http://localhost:9292'
  end

  configure :production do
    set :api_server, 'http://xxxx.herokuapp.com' ##temporary placeholder
  end

  configure :production, :development do
    enable :logging
  end

  before do
    @HOST_WITH_PORT = request.host_with_port
  end
end
