require 'rake/testtask'
require 'config_env/rake_tasks'

task :config do
  ConfigEnv.path_to_config("#{__dir__}/config/config_env.rb")
end

task :default => :spec

desc 'Run all tests'
Rake::TestTask.new(name=:spec) do |t|
  t.pattern = 'spec/*_spec.rb'
end

#for `rake db:migrate`
namespace :db do
  require_relative 'models/init.rb'
  require_relative 'config/init.rb'

  desc "Migrate all tables"
  task :migrate => [:article, :trend]
end

desc "Create article table"
task :article do
  begin
    Article.create_table
    puts 'Article table created'
  rescue Aws::DynamoDB::Errors::ResourceInUseException => e
    puts 'Article table already exists'
  end
end

desc "Create trend table"
task :trend do
  begin
    Trend.create_table
    puts 'Trend table created'
  rescue Aws::DynamoDB::Errors::ResourceInUseException => e
    puts 'Trend table already exists'
  end
end
