# frozen_string_literal: true

require_relative "rankable_methods/base"

module LexoRanker
  class Rankable < Module
    def initialize(adapter = :active_record)
      @adapter_setting = adapter
      @adapter = select_adapter
      class_eval do
        def self.included(klass)
          klass.include(LexoRanker::RankableMethods::Base)
          klass.include(@adapter)
        end
      end
    end

    private

    def select_adapter
      case @adapter_setting
      when :active_record
        require_relative "rankable_methods/adapters/active_record"
        RankableMethods::Adapters::ActiveRecord
      when :sequel
        require_relative "rankable_methods/adapters/sequel"
        RankableMethods::Adapters::Sequel
      else
        raise InvalidAdapterError, "#{@adapter_setting} is not a valid adapter. Choices are: :active_record, :sequel"
      end
    end
  end
end
