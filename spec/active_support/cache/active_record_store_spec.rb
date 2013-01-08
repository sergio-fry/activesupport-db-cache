require 'spec_helper.rb'

module ActiveSupport
  module Cache
    describe ActiveRecordStore do
      it "should store numbers"
      it "should store strings"
      it "should store objects"
      it "should expire entries"
      it "should use LIMIT"

      describe "#read" do
        before do
          @store = ActiveRecordStore.new
          @store.write("foo", 123)
        end

        it "should return nil if missed" do
          @store.read("bar").should be_nil
        end

        it "should read data if hit" do
          @store.read("foo").should eq(123)
        end
      end
    end
  end
end

