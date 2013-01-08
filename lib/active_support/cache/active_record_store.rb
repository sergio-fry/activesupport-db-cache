
module ActiveSupport
  module Cache
    class ActiveRecordStore < Store
      VERSION = "0.0.1"

      class CacheItem < ActiveRecord::Base
        def value
          Marshal.load(self[:value])
        end

        def expired?
          false
        end
      end

      def delete_entry(key, options)
      end

      def read_entry(key, options)
        CacheItem.find_by_key(key)
      end

      def write_entry(key, entry, options)
        item = CacheItem.find_or_initialize_by_key(key)
        item.value = Marshal.dump(entry.value)
        item.save
      end
    end
  end
end

