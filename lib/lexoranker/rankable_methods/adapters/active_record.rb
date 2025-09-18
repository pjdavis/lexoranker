# frozen_string_literal: true

module LexoRanker
  module RankableMethods
    module Adapters
      module ActiveRecord
        def self.included(klass)
          klass.extend(ClassMethods)
        end

        module ClassMethods
          def set_ranked_scope(field)
            scope :ranked, ->(direction: :asc) { where.not("#{field}": nil).order("#{field}": direction) }
          end

          def set_ranked_validations(field, scope = nil)
            if scope.nil?
              validates field, uniqueness: true, allow_nil: true
            else
              validates field, uniqueness: {scope: @rankable_scope}, allow_nil: true
            end
          end

          def create_ranked(attributes, position: nil, &block)
            instance = instance_ranked(attributes, position:, &block)
            instance.save
            instance
          end

          def create_ranked!(attributes, position: nil, &block)
            instance = instance_ranked(attributes, position:, &block)
            instance.save!
            instance
          end

          def ranks_around_position(id, position, scope_value: nil)
            scope = ranked.where.not(id: id)
            scope = scope.where("#{rankable_scope}": scope_value) unless scope_value.nil?
            scope.offset(position - 1).limit(2).pluck(:"#{rankable_column}")
          end

          private

          def instance_ranked(attributes, position: nil, &block)
            position = case position
            when :top, :bottom
              [:"move_to_#{position}"]
            when Integer
              [:move_to, position]
            else
              [:"move_to_#{rankable_default_insert_pos}"]
            end
            instance = new(attributes, &block)
            instance.send(*position)
            instance
          end
        end

        def ranked_collection
          @ranked_collection ||= begin
            scope = self.class.ranked
            scope = scope.where("#{self.class.rankable_scope}": send(self.class.rankable_scope)) if rankable_scoped?
            scope.pluck(:"#{self.class.rankable_column}")
          end
        end

        def move_to!(position)
          move_to(position)
          save!
        end
      end
    end
  end
end
