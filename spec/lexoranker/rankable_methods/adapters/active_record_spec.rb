# frozen_string_literal: true

require "active_record"

RSpec.describe "LexoRanker::RankableMethods::Adapters::ActiveRecord" do
  before do
    ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"
    ActiveRecord::Schema.define do
      self.verbose = false
      create_table :posts, force: true do |t|
        t.string :title
        t.string :rank
        t.string :scope
        t.timestamps
      end
    end
  end

  let(:rankable_opts) { {} }
  let(:post_class) do
    klass = Class.new(ActiveRecord::Base)
    klass.table_name = "posts"
    klass.include(LexoRanker::Rankable.new)
    klass.rankable(**rankable_opts)
    klass
  end

  describe ".rankable" do
    context "without scope" do
      it "validates that a rank can not be used twice" do
        post = post_class.create_ranked({title: "Post"})
        duplicate_rank_post = post_class.new(title: "Duplicate Rank", rank: post.rank)
        expect(duplicate_rank_post).not_to be_valid
      end
    end

    context "with scope" do
      let(:rankable_opts) { {scope_by: :scope} }

      it "validates that a rank can not be used twice in the same scope" do
        post = post_class.create_ranked({title: "Post", scope: "scope"})
        duplicate_rank_post = post_class.new(title: "Duplicate Rank", scope: "scope", rank: post.rank)
        expect(duplicate_rank_post).not_to be_valid
      end

      it "validates that a rank can be used twice in a different scope" do
        post = post_class.create_ranked({title: "Post", scope: "scope"})
        duplicate_rank_post = post_class.new(title: "Duplicate Rank", scope: "different", rank: post.rank)
        expect(duplicate_rank_post).to be_valid
      end
    end

    context "with a :top default_insert_pos" do
      let(:rankable_opts) { {default_insert_pos: :top} }

      it "defaults create_ranked to top position" do
        post_class.create_ranked({title: "Post"})
        new_post = post_class.create_ranked({title: "New Post"})
        expect(post_class.ranked.first).to eq new_post
      end
    end

    context "with an invalid default_insert_pos" do
      let(:rankable_opts) { {default_insert_pos: :middle} }

      it "raises an ArgumentError" do
        expect { post_class }.to raise_error(ArgumentError)
      end
    end
  end

  describe ".ranked" do
    let(:posts) do
      (0..2).map { |i| post_class.create(title: "Post #{i}") }
    end

    before do
      ranks = post_class.rankable_ranker.init_from_array(posts.reverse)
      posts.each { |post| post.update!(rank: ranks[post]) }
    end

    context "with default direction" do
      it "orders based on rank " do
        expect(post_class.ranked.map(&:id)).to eq posts.reverse.map(&:id)
      end
    end

    context "with descending direction" do
      it "orders by reverse rank" do
        expect(post_class.ranked(direction: :desc).map(&:id)).to eq posts.map(&:id)
      end
    end

    context "with unranked items" do
      it "does not include them in the results" do
        unranked = post_class.create(title: "Unranked")
        expect(post_class.ranked).not_to include(unranked)
      end
    end
  end

  describe ".create" do
    it "does not automatically rank an instance" do
      expect(post_class.create(title: "Unranked").rank_value).to be_nil
    end
  end

  describe ".create_ranked" do
    let(:posts) do
      (0..2).map { |i| post_class.create(title: "Post #{i}") }
    end

    before do
      ranks = post_class.rankable_ranker.init_from_array(posts.reverse)
      posts.each { |post| post.update!(rank: ranks[post]) }
    end

    context "with no position" do
      it "positions at the bottom" do
        new_post = post_class.create_ranked({title: "New Post"})
        expect(post_class.ranked.last).to eq new_post
      end
    end

    context "with :top position" do
      it "positions at the top" do
        new_post = post_class.create_ranked({title: "New Post"}, position: :top)
        expect(post_class.ranked.first).to eq new_post
      end
    end

    context "with numbered position" do
      it "positions at number" do
        new_post = post_class.create_ranked({title: "New Post"}, position: 1)
        expect(post_class.ranked.second).to eq new_post
      end
    end
  end

  describe "#move_to_top" do
    let(:posts) do
      (0..2).map { |i| post_class.create(title: "Post #{i}") }
    end

    before do
      ranks = post_class.rankable_ranker.init_from_array(posts.reverse)
      posts.each { |post| post.update!(rank: ranks[post]) }
    end

    it "moves the field to the top of the #ranked list" do
      new_post = post_class.new(title: "New Post")
      new_post.move_to_top
      new_post.save
      expect(post_class.ranked.first).to eq new_post
    end
  end

  describe "#move_to_top!" do
    let(:posts) do
      (0..2).map { |i| post_class.create(title: "Post #{i}") }
    end

    before do
      ranks = post_class.rankable_ranker.init_from_array(posts.reverse)
      posts.each { |post| post.update!(rank: ranks[post]) }
    end

    it "moves the field to the top of the #ranked list" do
      new_post = post_class.new(title: "New Post")
      new_post.move_to_top!
      expect(post_class.ranked.first).to eq new_post
    end
  end

  describe "#move_to_bottom" do
    let(:posts) do
      (0..2).map { |i| post_class.create(title: "Post #{i}") }
    end

    before do
      ranks = post_class.rankable_ranker.init_from_array(posts.reverse)
      posts.each { |post| post.update!(rank: ranks[post]) }
    end

    it "moves the field to the bottom of the #ranked list" do
      new_post = post_class.new(title: "New Post")
      new_post.move_to_bottom
      new_post.save
      expect(post_class.ranked.last).to eq new_post
    end
  end

  describe "#move_to_bottom!" do
    let(:posts) do
      (0..2).map { |i| post_class.create(title: "Post #{i}") }
    end

    before do
      ranks = post_class.rankable_ranker.init_from_array(posts.reverse)
      posts.each { |post| post.update!(rank: ranks[post]) }
    end

    it "moves the field to the bottom of the #ranked list" do
      new_post = post_class.new(title: "New Post")
      new_post.move_to_bottom!
      expect(post_class.ranked.last).to eq new_post
    end
  end

  describe "#move_to" do
    before do
      ranks = post_class.rankable_ranker.init_from_array(posts)
      posts.each { |post| post.update!(rank: ranks[post]) }
    end

    let(:posts) do
      (0..2).map { |i| post_class.create(title: "Post #{i}") }
    end

    context "when a position is in bounds" do
      it "moves the instance to the position" do
        new_post = post_class.new(title: "New Post")
        new_post.move_to(2)
        new_post.save

        expect(post_class.ranked.third).to eq(new_post)
      end
    end

    context "when a position is out of bounds" do
      it "moves the instance to the bottom" do
        new_post = post_class.new(title: "New Post")
        new_post.move_to(post_class.count + 10)
        new_post.save

        expect(post_class.ranked.last).to eq(new_post)
      end
    end

    context "when a position is negative" do
      it "raises an error" do
        new_post = post_class.new(title: "New Post")

        expect { new_post.move_to(-1) }.to raise_error LexoRanker::OutOfBoundsError
      end
    end
  end
end
