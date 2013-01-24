# Activesupport::Db::Cache

ActiveSupport::Cache store that stores data in a database table. Useful for NOT highload applications, when you do not want to use separate cache server like Memcache, Redis etc.. I am going to use it with Heroku application because of limitation of FREE cache storages.

Ruby on Rails support out of box.

## Features

 * Very LOW speed: think twice before use it! :)
 * persistence: store cache after rails restart
 * :expire_in option: cache lifetime for each item separetely
 * total rows limit: auto clean old items when large (5000 rows max)
 * ability to use external databse for cache store
 * debug mode: ability to gather information about cache usage (access_time, access_counter)

## Installation

Add this line to your application's Gemfile:

    gem 'activesupport-db-cache'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install activesupport-db-cache

Set cache store in a config/environments/production.rb:

    ..
    config.cache_store = ActiveSupport::Cache::ActiveRecordStore.new
    ..

Create migration for cache_items table:
    
    $ rails g migration create_cache_items

Copy migration paste

      def up
        connection = ActiveSupport::Cache::ActiveRecordStore::CacheItem.connection
        connection.create_table :cache_items do |t|
          t.string :key
          t.text :value
          t.text :meta_info, :text
          t.datetime :expires_at
          t.datetime :created_at
          t.datetime :updated_at
        end

        connection.add_index :cache_items, :key, :unique => true
        connection.add_index :cache_items, :expires_at
        connection.add_index :cache_items, :updated_at
      end

      def down
        ActiveSupport::Cache::ActiveRecordStore::CacheItem.connection.drop_table :cache_items
      end

Migrate database:
    
    $ rake db:migrate

Done!

## Usage

For usage details see ActiveSupport::Cache

### External database

By default ActiveRecordStore uses your ActiveRecord::Base.connection. If you whant to use some external database for cache pupose you should set ACTIVE_RECORD_CACHE_STORE_DATABASE_URL env variable:

    $ ACTIVE_RECORD_CACHE_STORE_DATABASE_URL="sqlite3://./db/test2.sqlite3" rails s

or postgres:

    $ ACTIVE_RECORD_CACHE_STORE_DATABASE_URL="postgresql://user:password@host/database" rails s

or any other.

For Heroku you should add config variable:

    $ heroku config:add ACTIVE_RECORD_CACHE_STORE_DATABASE_URL="postgresql://user:password@host/database"

### Debug mode

To profile your application you can use debug mode. In debug mode additional meta information is gathered: access_counter, access_time. Be careful: debug mode is EXTREMELY SLOW. Do not use in production for a long time.

    $ ACTIVE_RECORD_CACHE_STORE_DEBUG_MODE=1

For Heroku you should add config variable:

    $ heroku config:add ACTIVE_RECORD_CACHE_STORE_DEBUG_MODE=1

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
