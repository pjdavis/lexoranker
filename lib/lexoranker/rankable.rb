# frozen_string_literal: true

# The MIT License (MIT)
#
# Parts of this code Copyright (c) 2021 Richard Böhme
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative "rankable_methods/base"

module LexoRanker
  # Module for adding convenience methods to ActiveRecord or Sequel database adapters to support ranking items. See
  # {RankableMethods::Base} for class and instance methods added from this module.
  #
  class Rankable < Module
    # Instance the module to be included in the class for the database adapter.
    #
    # @param adapter [Symbol] the adapter to use
    # @return Rankable the module that can be included
    #
    # @example Include {Rankable} in an ActiveRecord model
    #   class MyList < ActiveRecord::Base
    #     include LexoRanker::Rankable.new(:active_record)
    #   end
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
