# frozen_string_literal: true

require_relative "lib/lexoranker/version"

Gem::Specification.new do |spec|
  spec.name = "lexoranker"
  spec.version = LexoRanker::VERSION
  spec.authors = ["PJ Davis"]
  spec.email = ["pj.davis@gmail.com"]

  spec.summary = "Lexicographic ranker for Ruby"
  spec.description = <<~DESC
    Library for sorting a set of elements based on their lexicographic order and the average distance between them
  DESC
  spec.homepage = "https://github.com/pjdavis/lexoranker"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir["lib/**/*"]

  spec.extra_rdoc_files = Dir["README.md", "CHANGELOG.md", "LICENSE.txt"]
  spec.rdoc_options += [
    "--title", "LexoRanker - Lexicographic Ranking for Ruby",
    "--main", "README.md",
    "--inline-source",
    "--quiet"
  ]
end
