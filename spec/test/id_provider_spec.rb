require "spec_helper"

RSpec.describe Test::IdProvider do
  describe :generate do
    subject { Test::IdProvider.generate }

    it { should be_instance_of String }
  end
end
