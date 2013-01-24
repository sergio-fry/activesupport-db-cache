require 'spec_helper.rb'
require 'ostruct'

module ActiveSupport
  module Cache
    describe ActiveRecordStore do
      before do
        @store = ActiveRecordStore.new
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

        def meta_info_for(key)
          OpenStruct.new(ActiveRecordStore::CacheItem.find_by_key(key).meta_info)
        end

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
  end
end

