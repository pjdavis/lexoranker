# frozen_string_literal: true

# Library for sorting a set of elements based on their lexicographic order and the average distance between them.
#
# {LexoRanker::Ranker} Library for generating lexicographic rankings based on the elements that come before and after
# the element that needs to be ranked.
#
# {LexoRanker::Rankable} Module that can be included into either ActiveRecord or Sequel database adapters for adding
# convenience methods for ranking instances.
#
# MIT License
#
# Parts of this code Copyright (c) 2019 SeokJoon.Yun
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module LexoRanker
  # LexoRanker is a lexicographic ranking system
  # that uses lexicographic ordering to sort items in a list, rather than
  # numbers.
  class Ranker
    # Returns the current object used as the character space. By default this is the built-in
    # LexoRanker::Ranker::CharacterSpace class, but can be overridden in the constructor
    #
    # @return Object the current character set
    attr_reader :character_space

    # @param character_space [#chr, #ord, #min, #max]
    # @return LexoRanker::Ranker a ranker
    #
    # @example Create a new ranker with the default character space
    #   ranker = LexoRanker::Ranker.new
    #
    # @example Create a ranker with a custom character space
    #   class CustomCharacterSpace
    #     CHARACTERS = %w[a b c d e]
    #     def self.chr(ord)
    #       CHARACTERS[ord]
    #     end
    #     def self.ord(chr)
    #       CHARACTERS.index(chr)
    #     end
    #     def min
    #       CHARACTERS.first
    #     end
    #     def max
    #       CHARACTERS.last
    #     end
    #   end
    #
    #   custom_ranker = LexoRanker::Ranker.new(CustomCharacterSpace)
    def initialize(character_space = CharacterSpace)
      @character_space = character_space
      @encoder = CharacterSpaceEncoder.new(character_space)
    end

    ##
    # Returns a LexoRank at the midpoint between the min and max character space. Used for when you need to rank only
    # one item in a list
    #
    # @return [String] the new LexoRank
    #
    # @example Return a LexoRank with no previous or following items.
    #   LexoRanker::Ranker.new.only # => 'M'
    def only
      value_between(before: character_space.min, after: character_space.max)
    end

    ##
    # Return a LexoRank that comes before what would be the first item of a LexoRanked list. If `first_item` is nil,
    # returns a LexoRank for a list with one element
    #
    # @param first_value [String, NilClass] the first LexoRank value of the list the new rank will be inserted into
    # @return [String] a LexoRank before first_value
    #
    # @example Return a LexoRank before `first_value`
    #   LexoRanker::Ranker.new.first('M') # => 'H'
    #
    # @example Return a LexoRank with a nil `first_value`
    #   LexoRanker::Ranker.new.first(nil) # => 'M'
    def first(first_value)
      value_between(before: character_space.min, after: first_value)
    end

    ##
    # Return a LexoRank that comes after what would be the last item of a LexoRanked list. If `last_item` is nil,
    # returns a LexoRank for a list with one element
    #
    # @param last_value [String, NilClass] the last LexoRank value of the list the new rank will be inserted into
    # @return [String] a LexoRank after last_value
    #
    # @example Return a LexoRank after `last_value`
    #   LexoRanker::Ranker.new.last('M') # => 'T'
    #
    # @example Return a Lexorank with a nil `last_value`
    #   LexoRanker::Ranker.new.last(nil) # => 'M'
    def last(last_value)
      value_between(before: last_value, after: character_space.max)
    end

    ##
    # Return a LexoRank between `previous` and `following` arguments. Either argument can be called with `NilClass` to
    # return a LexoRank that is after/before the passed argument, but not necessarily before/after any other particular
    # element.
    #
    # Passing `NilClass` as an argument, and then attempting to insert a LexoRank into an existing list may end up with
    # identical LexoRank rankings, which is invalid.
    #
    # @param previous [String, NilClass] the LexoRank that will be preceding the returned LexoRank
    # @param following [String, NilClass] the LexoRank that will be following the returned LexoRank
    # @return [String] a LexoRank between `previous` and `following`
    #
    # @example Return a LexoRank between `previous` and `following`
    #   LexoRanker::Ranker.new.between('M', 'T') # => 'R'
    #
    # @example Return a LexoRank anywhere before `following`
    #   LexoRanker::Ranker.new.between(nil, 'M') # => 'H'
    def between(previous, following)
      value_between(before: previous, after: following)
    end

    ##
    # Init a new LexoRanking for an already sorted list of elements
    # @todo: Will cause issues with lists that have duplicate elements, either warn or fix.
    #
    # @param list [Array] the existing list to be assigned LexoRanks
    # @return [Hash] a hash with key being the element of the list, and value being the assigned LexoRank
    #
    # @example Return a hash with element => LexoRank hash
    #   list = [1,2,3]
    #   LexoRanker::Ranker.new.init_from_array(list) # { 1 => 'M', 2 => 'T', 3 => 'W' }
    def init_from_array(list)
      raise ArgumentError, "`list` can not be nil" if list.nil?

      list.zip(balanced_ranks(list.size)).to_h
    end

    ##
    # Return an array of rankings in order that cover `element_count` number of elements.
    #
    # @param element_count [Integer] number of ranking elements
    # @return [Array] an array of ranks in order.
    #
    # @example Return an array with 5 elements
    #   list = LexoRanker::Ranker.new.balanced_ranks(5) # ["2", "E", "Q", "c", "o"]
    def balanced_ranks(element_count)
      raise ArgumentError, "`element_count` must be greater than zero" if element_count.nil? || element_count <= 0

      start = 2
      places = (Math.log(element_count) / Math.log(character_space.size)).ceil
      ending = (character_space.size**places) - 2

      Array.new(element_count).map.with_index do |_, i|
        encoder.encode(start + (i.to_f / element_count.to_f * ending).round).rjust(places, character_space.min)
      end
    end

    private

    attr_reader :encoder

    # rubocop:disable Metrics/MethodLength
    def value_between(before:, after:)
      before ||= character_space.min
      after ||= character_space.max
      rank = ""

      (before.length + after.length).times do |i|
        prev_char = get_char(before, i, character_space.min)
        after_char = get_char(after, i, character_space.max)

        if prev_char == after_char
          rank += prev_char
          next
        end

        mid = mid_char(prev_char, after_char)

        if mid == prev_char || mid == after_char
          rank += prev_char
          next
        end

        rank += mid
        break
      end

      raise InvalidRankError, "Computed rank #{rank} comes after the provided after rank #{after}" if rank >= after

      rank
    end

    # rubocop:enable Metrics/MethodLength

    def mid_char(prev, after)
      character_space.chr(((character_space.ord(prev) + character_space.ord(after)) / 2.0).round)
    end

    def get_char(string, index, default)
      (index >= string.length) ? default : string[index]
    end

    class CharacterSpaceEncoder
      attr_reader :character_space

      def initialize(character_space)
        @character_space = character_space
      end

      def encode(num)
        str = ""
        while num > 0
          str = character_space.chr(num % character_space.size) + str
          num /= character_space.size
        end
        str
      end
    end

    class CharacterSpace
      CHARACTERS = [*"0".."9", *"A".."Z", *"a".."z"].sort.freeze

      class EmptyCharacterSpaceError < StandardError; end

      class CharNotInCharacterSpaceError < StandardError; end

      class IndexOutOfCharacterSpaceError < StandardError; end

      class << self
        ##
        # @return [Integer]
        def ord(char)
          CHARACTERS.index(char) || (raise CharNotInCharacterSpaceError,
            "Character: #{char} not found in current character space")
        end

        ##
        # @return [String]
        def chr(ord)
          CHARACTERS[ord] || (raise IndexOutOfCharacterSpaceError, "Index: #{ord} outside current character space")
        end

        ##
        # @return [String]
        def min
          CHARACTERS.first || (raise EmptyCharacterSpaceError, "Character Space is empty")
        end

        ##
        # @return [String]
        def max
          CHARACTERS.last || (raise EmptyCharacterSpaceError, "Character Space is empty")
        end

        def size
          CHARACTERS.size
        end
      end
    end
  end
end
