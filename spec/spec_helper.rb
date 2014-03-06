# coding: utf-8
require 'pathname'
require 'logger'

SPEC_ROOT = Pathname.new(File.dirname(__FILE__))

require 'bundler/setup'
require 'rspec'
require 'database_cleaner'
require 'active_record'

ActiveRecord::Base.establish_connection(YAML.load(SPEC_ROOT.join('database.yml').read))
ActiveRecord::Base.logger = Logger.new(ENV['DEBUG'] ? $stderr : '/dev/null')
ActiveRecord::Base.logger.formatter = proc do |severity, datetime, progname, msg|
  "#{datetime.strftime('%H:%M:%S.%L')}: #{msg}\n"
end

load SPEC_ROOT.join('schema.rb')
require SPEC_ROOT.join('support', 'models').to_s

DatabaseCleaner.strategy = :transaction

# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.start
    example.run
    DatabaseCleaner.clean
  end
end

begin
  require 'simplecov'
  SimpleCov.start
rescue LoadError, NameError
  # ok
end

require 'active_record/hierarchical_query'
