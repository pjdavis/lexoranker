# frozen_string_literal: true

RSpec.describe LexoRanker::Rankable do
  describe "#new" do
    context "with invalid adapter" do
      it "raises InvalidAdapterError" do
        expect { described_class.new(:invalid) }.to raise_error(LexoRanker::InvalidAdapterError)
      end
    end
  end
end
