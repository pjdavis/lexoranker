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
            define_method :ranked do |direction = :asc|
              dataset_module do
                order(Sequel.send(direction, field))
              end
            end
          end

          def set_ranked_validations(field, scope = nil)
            args = scope.nil? ? field : [field, scope]
            define_method :validate do
              super
              validates_unique(args)
            end
          end
        end

        def create_ranked(attributes, position: nil, &_block)
          instance = new
          instance.set(attributes)
          instance.move_to(position)
          instance.save
        end
      end
    end
  end
end
