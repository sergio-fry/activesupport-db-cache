require "base64"

module ActiveSupport
  module Cache
    class ActiveRecordStore < Store
      VERSION = "0.0.2"

      # do not allow to store more items than
      ITEMS_LIMIT = 5000

      # set database url:
      #   ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'] = "sqlite3://./db/test2.sqlite3"
      class CacheItem < ActiveRecord::Base
        self.table_name = ENV['ACTIVE_RECORD_CACHE_STORE_TABLE'] || 'cache_items'
        establish_connection ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'] if ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'].present?

        def value
          Marshal.load(::Base64.decode64(self[:value]))
        end

        def expired?
          self[:expires_at].try(:past?) || false
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
        options = options.clone.symbolize_keys
        item = CacheItem.find_or_initialize_by_key(key)
        item.value = ::Base64.encode64(Marshal.dump(entry.value))
        item.expires_at = options[:expires_in].try(:since)

        remove_expired_items
        item.save
      end

      private

      def remove_expired_items
        # remove expired
        CacheItem.where("expires_at < ?", Time.now).delete_all

        # free some space
        if CacheItem.count >= (ITEMS_LIMIT-1)
          oldest_updated_at = CacheItem.select(:updated_at).order(:updated_at).offset((ITEMS_LIMIT.to_f * 0.2).round).first.try(:updated_at)

          CacheItem.where("updated_at < ?", oldest_updated_at).delete_all
        end
      end
    end
  end
end

