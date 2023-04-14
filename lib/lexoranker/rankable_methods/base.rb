# frozen_string_literal: true

module LexoRanker
  module RankableMethods
    module Base
      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        attr_reader :rankable_column, :rankable_scope, :rankable_ranker, :rankable_default_insert_pos

        def rankable_by(field: :rank, scope_by: nil, ranker: LexoRanker::Ranker, default_insert_pos: :bottom)
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
      end

      def move_to_top
        move_to(0)
      end

      def move_to_top!
        move_to!(0)
      end

      def move_to_bottom
        move_to(ranked_collection.length)
      end

      def move_to_bottom!
        move_to!(ranked_collection.length)
      end

      def rank_value
        send(self.class.rankable_column)
      end

      def move_to(position)
        raise OutOfBoundsError, "position mus be 0 or a positive integer" if position.negative?
        position = ranked_collection.length if position > ranked_collection.length

        previous, following = if position.zero?
          [nil, ranked_collection.first]
        else
          self.class.ranks_around_position(id, position)
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
