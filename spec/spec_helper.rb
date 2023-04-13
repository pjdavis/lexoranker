# frozen_string_literal: true

require "simplecov"
SimpleCov.start

require "lexoranker"

RSpec.configure do |config|
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.order = :random

  Kernel.srand(config.seed)
end
