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
        end
      end
    end
  end
end
