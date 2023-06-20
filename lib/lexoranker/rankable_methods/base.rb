# frozen_string_literal: true

module LexoRanker
  module RankableMethods
    module Base
      # Ruby lifecycle callback, executed when included into other classes
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        # The column to hold the rank value
        # @return [String] the rank value
        attr_reader :rankable_column

        # The scope of the rankings
        # @return [String] the column the rankings are scoped to
        attr_reader :rankable_scope

        # The ranker to use
        # @return [Class] The ranker being used
        attr_reader :rankable_ranker

        # Default insert position for newly rank-created elements
        # @return [Symbol] The default position
        attr_reader :rankable_default_insert_pos

        # Method to set up the rankable column and add the rankable scope and validations to the class including
        # Rankable
        # @param field [String, Symbol] The field to use for the ranking column.
        # @param scope_by [String, Symbol] The field that is used to scope the rankings
        # @param ranker [Class] The class used to determine rankings
        # @param default_insert_pos [Symbol] the default position for newly created rankable elements to be placed.
        # @return [void]
        def rankable_by(field: :rank, scope_by: nil, ranker: LexoRanker::Ranker.new, default_insert_pos: :bottom)
          unless %i[top bottom].include?(default_insert_pos)
            raise ArgumentError,
              "#{default_insert_pos} is not a valid default_insert_position. Must be one of [:top, :bottom]"
          end
          @rankable_column = field
          @rankable_scope = scope_by
          @rankable_ranker = ranker
          @rankable_default_insert_pos = default_insert_pos

          set_ranked_scope(field)
          set_ranked_validations(field, @rankable_scope)
        end

        alias_method :rankable, :rankable_by

        # Create a new instance of the rankable class with a ranking at `position`.
        #
        # @param attributes [Hash] attributes for the newly created instance
        # @param position [Integer] position that the instance should be created at
        # @yield [instance] The instance before it is saved.
        # @return [Object] The record that was created
        def create_ranked(attributes, position: nil, &block)
        end
      end

      # Move an instance to the top of the rankings
      #
      # @return [String] The rank the instance has been assigned
      #
      # @example Moving an element to the top of the rankings (ActiveRecord, #rank column)
      #   element = Element.find('some_id')
      #   element.move_to_top # => 'aaa'
      #   element.rank # => 'aaa'
      #   element.changed? => true
      def move_to_top
        move_to(0)
      end

      # Move an instance to the top of the rankings and save. Raises an error if it can not be saved
      #
      # @return [String] The rank the instance has been assigned
      #
      # @example Moving an element to the top of the rankings (ActiveRecord, #rank column)
      #   element = Element.find('some_id')
      #   element.move_to_top! # => 'aaa'
      #   element.rank # => 'aaa'
      #   element.changed? => false
      def move_to_top!
        move_to!(0)
      end

      # Move an instance to the bottom of the rankings
      #
      # @return [String] The rank the instance has been assigned
      #
      # @example Moving an element to the bottom of the rankings (ActiveRecord, #rank column)
      #   element = Element.find('some_id')
      #   element.move_to_bottom # => 'zzz'
      #   element.rank # => 'zzz'
      #   element.changed? => true
      def move_to_bottom
        move_to(ranked_collection.length)
      end

      # Move an instance to the bottom of the rankings and save. Raises an error if it can not be saved.
      #
      # @return [String] The rank the instance has been assigned
      #
      # @example Moving an element to the bottom of the rankings (ActiveRecord, #rank column)
      #   element = Element.find('some_id')
      #   element.move_to_bottom! # => 'zzz'
      #   element.rank # => 'zzz'
      #   element.changed? => false
      def move_to_bottom!
        move_to!(ranked_collection.length)
      end

      # Returns the value of the rank column
      #
      # @return [String] the rank the instance has been assigned
      #
      # @example Getting the rank of an instance
      #   element = Element.find('some_id')
      #   element.rank_value # => 'rra'
      def rank_value
        send(self.class.rankable_column)
      end

      # Moves an instance to a rank that corresponds to position (0-indexed). Throws OutOfBoundsError if position is
      # negative
      #
      # @param position [Integer] the position to move the instance to (0-indexed)
      # @return [String] the rank the instance has been assigned
      # @raise [LexoRanker::OutOfBoundsError] raised when the position is negative
      #
      # @example moving an instance to the 3rd position
      #   element = Element.find('some_id')
      #   element.move_to(2) # => 'Ea'
      #   element.changed? # => false
      #
      # @example moving an instance to a negative position
      #   element = Element.find('some_id')
      #   element.move_to(-1) # OutOfBoundsError raised
      def move_to(position)
        raise OutOfBoundsError, "position mus be 0 or a positive integer" if position.negative?
        position = ranked_collection.length if position > ranked_collection.length

        previous, following = if position.zero?
          [nil, ranked_collection.first]
        else
          scope_value = send(self.class.rankable_scope) if rankable_scoped?
          self.class.ranks_around_position(id, position, scope_value: scope_value)
        end

        rank = self.class.rankable_ranker.between(previous, following)

        send("#{self.class.rankable_column}=", rank)
      end

      private

      def rankable_scoped?
        !self.class.rankable_scope.nil?
      end
    end
  end
end
