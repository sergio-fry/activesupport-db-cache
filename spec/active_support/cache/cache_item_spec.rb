require 'spec_helper.rb'

describe ActiveRecordStore::CacheItem do
  describe '#expires_at' do
    it 'should return the expiration instant in seconds since the epoch' do
      cache_item = ActiveRecordStore::CacheItem.new(:expires_at => 5.minutes.from_now)
      cache_item.expires_at.should be_instance_of Float
    end
  end
end