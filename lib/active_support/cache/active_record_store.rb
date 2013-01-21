require "base64"

module ActiveSupport
  module Cache
    class ActiveRecordStore < Store
      VERSION = "0.0.2"

      # set database url:
      #   ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'] = "sqlite3://./db/test2.sqlite3"
      class CacheItem < ActiveRecord::Base
        self.table_name = ENV['ACTIVE_RECORD_CACHE_STORE_TABLE'] || 'cache_items'
        establish_connection ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'] if ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'].present?

        def value
          Marshal.load(Base64.decode64(self[:value]))
        end

        def expired?
          false
        end
      end

      def clear
        CacheItem.delete_all
      end

      def delete_entry(key, options)
        CacheItem.delete_all(:key => key)
      end

      def read_entry(key, options)
        CacheItem.find_by_key(key)
      end

      def write_entry(key, entry, options)
        item = CacheItem.find_or_initialize_by_key(key)
        item.value = Base64.encode64(Marshal.dump(entry.value))
        item.save
      end
    end
  end
end

