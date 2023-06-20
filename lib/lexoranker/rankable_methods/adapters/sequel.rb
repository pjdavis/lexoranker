# frozen_string_literal: true

module LexoRanker
  module RankableMethods
    module Adapters
      module Sequel
        def self.included(klass)
          klass.extend(ClassMethods)
        end

        module ClassMethods
          def set_ranked_scope(field)
            dataset_module do
              define_method(:ranked) do |direction: :asc|
                order(::Sequel.send(direction, field)).exclude(field => nil)
              end
            end
          end

          def set_ranked_validations(field, scope = nil)
            args = scope.nil? ? field : [field, scope]
            plugin :validation_helpers
            define_method :validate do
              super()
              validates_unique(args)
            end
          end

          def create_ranked(attributes, position: nil, &block)
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
            instance.save
            instance
          end

          def ranks_around_position(id, position, scope_value: nil)
            scope = ranked.exclude(id: id)
            scope = scope.where("#{rankable_scope}": scope_value) unless scope_value.nil?
            scope.offset(position - 1).limit(2).select(rankable_column).map(&:"#{rankable_column}")
          end
        end

        def ranked_collection
          scope = self.class.ranked
          scope = scope.where("#{self.class.rankable_scope}": send(self.class.rankable_scope)) if rankable_scoped?
          scope.select(self.class.rankable_column).map(&:"#{self.class.rankable_column}") || []
        end

        def move_to!(position)
          move_to(position)
          save
        end
      end
    end
  end
end
