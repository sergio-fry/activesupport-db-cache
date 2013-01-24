require 'rubygems'
require 'bundler/setup'
require 'activesupport-db-cache'
require 'timecop'

require "sqlite3"
ActiveRecord::Base.establish_connection(:adapter => 'sqlite3', :database => 'db/test.sqlite3')
ActiveRecord::Base.connection.create_table(:cache_items, :force => true) do |t|
  t.column :key, :string
  t.column :value, :text
  t.column :meta_info, :text
  t.column :expires_at, :datetime
  t.column :created_at, :datetime
  t.column :updated_at, :datetime
end
ActiveRecord::Base.connection.add_index(:cache_items, :key, :unique => true)
ActiveRecord::Base.connection.add_index(:cache_items, :created_at)
ActiveRecord::Base.connection.add_index(:cache_items, :updated_at)

require 'logger'
logfile = File.open(File.expand_path("../../log/test.log", __FILE__), 'a')
ActiveRecord::Base.logger = Logger.new(logfile)

Dir['./spec/support/*.rb'].map {|f| require f }

RSpec.configure do |config|
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
end
