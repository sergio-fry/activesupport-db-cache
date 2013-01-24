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

  [true, false].each do |debug_mode|
    describe "cache use when debug_mode='#{debug_mode}'" do
      before do
        @store.stub(:debug_mode?).and_return(debug_mode)
      end

      it "should store numbers" do
        @store.write("foo", 123)
        @store.read("foo").should eq(123)
      end

      it "should store strings" do
        @store.write("foo", "bar string")
        @store.read("foo").should eq("bar string")
      end

      it "should store hash" do
        @store.write("foo", { :a => 123 })
        @store.read("foo").keys.should include(:a)
        @store.read("foo")[:a].should eq(123)
      end

      it "should expire entries" do
        @store.write :foo, 123, :expires_in => 5.minutes
        @store.read(:foo).should eq(123)
        Timecop.travel 6.minutes.since do
          @store.read(:foo).should be_blank
        end
      end

      it "should use ITEMS_LIMIT" do
        silence_warnings { ActiveRecordStore.const_set(:ITEMS_LIMIT, 10) }
        @store.clear

        15.times do |i|
          @store.write(i, 123)

          ActiveRecordStore::CacheItem.count
        end

        ActiveRecordStore::CacheItem.count.should <= 10
      end

      describe "#read" do
        before do
          @store.write("foo", 123)
        end

        it "should return nil if missed" do
          @store.read("bar").should be_nil
        end

        it "should read data if hit" do
          @store.read("foo").should eq(123)
        end
      end

      describe "#fetch" do
        it "should return calculate if missed" do
          @store.delete(:foo)
          obj = mock(:obj)
          obj.should_receive(:func).and_return(123)

          @store.fetch(:foo) { obj.func }.should eq(123)
        end

        it "should read data from cache if hit" do
          @store.write(:foo, 123)
          obj = mock(:obj)
          obj.should_not_receive(:func)

          @store.fetch(:foo) { obj.func }.should eq(123)
        end
      end

      describe "#clear" do
        it "should clear cache" do
          @store.write("foo", 123)
          @store.write("bar", "blah data")
          @store.clear
          @store.read("foo").should be_blank
          @store.read("bar").should be_blank
        end
      end

      describe "#delete" do
        it "should delete entry" do
          @store.write("foo", 123)
          @store.delete("foo")
          @store.read("foo").should be_blank
        end
      end

      describe "cache item meta info" do
        before { @store.clear }

        describe "item version" do
          it "should be 1 for a new cache item", :filter => true do
            @store.write(:foo, "foo")
            meta_info_for(:foo).version.should eq(1)
          end

          it "should be incremented after cache update" do
            @store.write(:foo, "bar")
            meta_info_for(:foo).version.should eq(1)

            @store.write(:foo, "123")
            meta_info_for(:foo).version.should eq(2)

            @store.write(:foo, "hoo")
            meta_info_for(:foo).version.should eq(3)
          end

          it "should not be incremented if no data change" do
            @store.write(:foo, "bar")
            @store.write(:foo, "bar")
            meta_info_for(:foo).version.should eq(1)
          end
        end
      end
    end
  end
end

