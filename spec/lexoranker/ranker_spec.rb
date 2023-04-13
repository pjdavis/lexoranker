# frozen_string_literal: true

RSpec.describe LexoRanker::Ranker do
  describe ".only" do
    it "returns a rank for the only position" do
      expect(described_class.only).not_to be_nil
    end
  end

  describe ".first" do
    context "with a present first lexorank" do
      it "returns a rank in the first position" do
        collection = %w[G M T]
        rank = described_class.first(collection.first)
        collection << rank
        expect(collection.sort).to eq([rank, "G", "M", "T"])
      end
    end

    context "with a nil first lexorank" do
      it "returns a rank" do
        expect(described_class.first(nil)).not_to be_nil
      end
    end
  end

  describe ".last" do
    context "with a present last lexorank" do
      it "returns a rank in the last position" do
        collection = %w[G M T]
        rank = described_class.last(collection.last)
        collection << rank
        expect(collection.sort).to eq(["G", "M", "T", rank])
      end
    end

    context "with a nil last lexorank" do
      it "returns a rank" do
        expect(described_class.last(nil)).not_to be_nil
      end
    end
  end

  describe ".between" do
    context "with a previous and following" do
      it "returns a rank between the before and after" do
        collection = described_class.init_from_array([0, 1, 2, 3, 4, 5])
        rank = described_class.between(collection[1], collection[2])
        collection[:new_element] = rank
        expect(collection.sort_by { |_k, v| v }[2].first).to eq(:new_element)
      end
    end

    context "with a nil previous and following" do
      it "returns a rank at the beginning of the collection" do
        collection = described_class.init_from_array([0, 1, 2, 3])
        rank = described_class.between(nil, collection[0])
        expect(rank).to be < collection[0]
      end
    end

    context "with a previous and nil following" do
      it "returns a rank at the end of the collection" do
        collection = described_class.init_from_array([0, 1, 2, 3])
        rank = described_class.between(collection[3], nil)
        expect(rank).to be > collection[3]
      end
    end

    context "with a before argument that comes after the after argument" do
      it "raises an invalid rank error" do
        expect { described_class.between("S", "R") }.to raise_error(LexoRanker::InvalidRankError)
      end
    end

    context "with a multi-character rank where the first character matches" do
      it "returns a rank between the provided ranks" do
        expect(described_class.between("ab", "ad")).to be_between("ab", "ad")
      end
    end
  end

  describe "init_from_array" do
    context "when pass an array" do
      it "returns a hash, with the element as the key, and lexorank as the value" do
        collection = [1, 2, "three", 4, 5]
        ranks = described_class.init_from_array(collection)
        expect(ranks.sort_by { |_k, v| v }.to_h.keys).to eq([1, 2, "three", 4, 5])
      end
    end

    context "when passed nil" do
      it "raises ArgumentError" do
        expect { described_class.init_from_array(nil) }.to raise_error(ArgumentError)
      end
    end
  end
end
