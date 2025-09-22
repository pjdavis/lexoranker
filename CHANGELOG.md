## 2025-09-22
* Release 0.4.0
* Bump Gems to current versions
* Add .create_ranked! to ActiveRecord adapter
## 2025-06-10
* Release 0.3.0
* Create initial RubyGems Release
## 2025-06-09
* Bump Gems to current versions
* Replace StandardRB with Rubocop for running linter (still uses the
  StandardRB rules under the hood, but lets me configure the RSpec linter)
* Another round of autocorrected lint fixes.
## 2023-06-20
* Update `.ranks_around_position` to respect scope_by
* Version 0.2.0
## 2023-05-09
* `#init_from_array` now uses the `#balanced_ranks` method to generate the
  initial set of ranks. This is a more balanced way of generating the ranks
  that should be relatively uniform across the character space.
## 2023-04-28
* Allow custom character sets in Ranker
* Add documentation and update README
## 2023-04-13
* Initial Commit
* Initial Ranker implementation
* Initial Rankable implementation for Active Record
* Initial Rankable implementation for Sequel
