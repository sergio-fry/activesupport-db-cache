require 'spec_helper.rb'
require 'ostruct'

include ActiveSupport::Cache

describe ActiveRecordStore do
  def meta_info_for(key)
    OpenStruct.new(ActiveRecordStore::CacheItem.find_by_key(key).meta_info)
  end

  before do
    @store = ActiveRecordStore.new
  end

  describe "debug mode" do
    before { @store.clear }
    context "debug mode is ON" do
      before do
        @store.stub(:debug_mode?).and_return(true)
      end

      describe "access_time" do
        it "should be nil for a ne item" do
          @store.write(:foo, 123)
          meta_info_for(:foo).access_time.should be_nil
        end

        it "should store last access time" do
          @store.write(:foo, 123)

          atime = 10.minutes.ago

          Timecop.freeze atime do
            @store.read(:foo)
          end

          meta_info_for(:foo).access_time.should eq(atime)
        end
      end

      describe "access_counter" do
        it "should be 0 for a new item" do
          @store.write(:foo, 123)
          meta_info_for(:foo).access_counter.should eq(0)
        end

        it "should be incremented after each cache read" do
          @store.write(:foo, 123)

          @store.read(:foo)
          meta_info_for(:foo).access_counter.should eq(1)

          @store.read(:foo)
          meta_info_for(:foo).access_counter.should eq(2)

          @store.read(:foo)
          meta_info_for(:foo).access_counter.should eq(3)
        end
      end
    end

    context "debug mode is OFF" do
      before do
        @store.stub(:debug_mode?).and_return(false)
      end

      describe "access_counter" do
        it "should not be incremented after cache read" do
          @store.write(:foo, 123)

          @store.read(:foo)
          meta_info_for(:foo).access_counter.should eq(0)

          @store.read(:foo)
          meta_info_for(:foo).access_counter.should eq(0)
        end
      end

      describe "access_time" do
        it "should not be updated" do
          @store.write(:foo, 123)
          @store.read(:foo)
          meta_info_for(:foo).access_time.should be_nil
        end
      end
    end
  end
end


