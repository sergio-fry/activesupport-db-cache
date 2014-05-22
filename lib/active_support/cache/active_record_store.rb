require "base64"
require "ostruct"

module ActiveSupport
  module Cache
    class ActiveRecordStore < Store
      VERSION = "0.0.3"

      # do not allow to store more items than
      ITEMS_LIMIT = 5000

      # set database url:
      #   ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'] = "sqlite3://./db/test2.sqlite3"
      class CacheItem < ActiveRecord::Base
        self.table_name = ENV['ACTIVE_RECORD_CACHE_STORE_TABLE'] || 'cache_items'
        establish_connection ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'] if ENV['ACTIVE_RECORD_CACHE_STORE_DATABASE_URL'].present?

        cattr_accessor :debug_mode

        serialize :meta_info, Hash
        before_save :init_meta_info, :bump_version

        def debug_mode?
          debug_mode
        end

        DEFAULT_META_INFO = { :version => 0, :access_counter => 0 }

        def value
          Marshal.load(::Base64.decode64(self[:value])) if self[:value].present?
        end

        def value=(new_value)
          @raw_value = new_value
          self[:value] = ::Base64.encode64(Marshal.dump(@raw_value))
        end

        def expired?
          read_attribute(:expires_at).try(:past?) || false
        end

        # From ActiveSupport::Cache::Store::Entry
        # Seconds since the epoch when the entry will expire.
        def expires_at
          read_attribute(:expires_at).try(:to_f)
        end

        private

        def bump_version
          meta_info[:version] = meta_info[:version] + 1 if value_changed?
        end

        def init_meta_info
          self.meta_info = DEFAULT_META_INFO.merge(meta_info)
        end
      end

      def clear
        CacheItem.delete_all
      end

      def delete_entry(key, options)
        CacheItem.delete_all(:key => key)
      end

      def read_entry(key, options={})
        item = CacheItem.find_by_key(key)

        if item.present? && debug_mode?
          item.meta_info[:access_counter] += 1
          item.meta_info[:access_time] = Time.now
          item.save
        end

        item
      end

      def write_entry(key, entry, options)
        options = options.clone.symbolize_keys
        item = CacheItem.find_or_initialize_by(:key => key)
        item.debug_mode = debug_mode?
        item.value = entry.value
        item.expires_at = options[:expires_in].try(:since)
        item.save
      rescue ActiveRecord::RecordNotUnique
      ensure
        free_some_space
      end

      def debug_mode?
        ENV['ACTIVE_RECORD_CACHE_STORE_DEBUG_MODE'] == "1"
      end

      private

      def free_some_space
        # free some space
        if CacheItem.count >= ITEMS_LIMIT
          # remove expired
          CacheItem.where("expires_at < ?", Time.now).delete_all

          # remove old items
          oldest_updated_at = CacheItem.select(:updated_at).order(:updated_at).offset((ITEMS_LIMIT.to_f * 0.2).round).first.try(:updated_at)
          CacheItem.where("updated_at < ?", oldest_updated_at).delete_all
        end
      end
    end
  end
end

