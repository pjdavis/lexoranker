# frozen_string_literal: true

require_relative "lexoranker/version"
require_relative "lexoranker/ranker"
require_relative "lexoranker/rankable"

module LexoRanker
  class Error < StandardError; end

  class OutOfBoundsError < Error; end

  class InvalidAdapterError < Error; end

  class InvalidRankError < Error; end
end
