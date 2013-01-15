require 'spec_helper.rb'

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

      it "should expire entries"
      it "should use LIMIT"

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
    end
  end
end

