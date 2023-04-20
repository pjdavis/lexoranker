# frozen_string_literal: true

require_relative "lexoranker/version"
require_relative "lexoranker/ranker"
require_relative "lexoranker/rankable"

module LexoRanker
  class Error < StandardError; end

  # Error raised when attempting to move a ranked element to a negative rank
  class OutOfBoundsError < Error; end

  # Error raised when attempting to use an adapter that is not available to LexoRanker::Rankable
  class InvalidAdapterError < Error; end

  # Error raised when attempting to rank an element between 2 ranks that are out of order
  class InvalidRankError < Error; end
end
