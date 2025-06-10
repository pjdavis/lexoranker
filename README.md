# LexoRanker

LexoRanker is a library for sorting a set of elements based on their
lexicographic order and the average distance between them. This method allows
for user-defined ordering of elements without having to update existing rows,
and with longer intervals between the need for rebalancing. LexoRanker is
stateless, meaning that you only need to know the rank of the elements before
and after the element you want to sort.

Inspired by Atlassian's LexoRanker.

## Installation

Add this to your application's `Gemfile`:

`gem 'lexoranker'`

And then run:

`$ bundle install`

## Ruby

### Usage

You can use the ranker stand-alone via the `LexoRanker::Ranker` class.

```ruby
# Use `.only` to get the first ranking of a set.
LexoRanker::Ranker.new.only # => "M"

# Use `.between` to get the ranking of an element between two other rankings
LexoRanker::Ranker.new.between("M", "T") # => "R"

# Use `.first` to get the ranking that comes before the first element
LexoRanker::Ranker.new.first("M") # => "H"

# Use `.init_from_enumerable(enum_list)` to generate a rank for each element
# in an already sorted list of elements, returns a hash with the elements as
# the keys and the rank as values.
list = %w[my sorted list]
LexoRanker::Ranker.new.init_from_enumerable(list) # { "my" => "M", "sorted" => "R", "list" => "t"}
```

## Ruby on Rails

### Setup

You can also use LexoRanker combined with ActiveRecord to add ranking
support to any model.

Each model that uses LexoRanker will need to have a column used to hold the
rankings. Then include the `LexoRanker::Rankable.new` module in the model, and
call the
`.rankable` method.

```ruby

class Page < ApplicationRecord
  include LexoRanker::Rankable.new

  rankable
end
```

By default, LexoRanker will use the `rank` column, but this, and several
other options can be customized.

```ruby

class Page < ApplicationRecord
  include LexoRanker::Rankable.new

  rankable field: "priority", # Set the name of the column used to hold ranking information
    scope_by: "department_id", # Set the name of the column used to scope the uniqueness validation to
    default_insert_pos: :top # The default position to use when inserting a new row with `.create_ranked` that doesn't include a rank
end
```

### Usage

Given the setup:

```ruby

class Page < ApplicationRecord
  include LexoRanker::Rankable.new

  rankable
end
```

```ruby
# Creating an instance with a ranking:
Page.create_ranked({name: "My Awesome Page"}, position: :top)

# Getting the ranked list of rows (can be chained with other scopes)
Page.ranked # or Page.ranked(direction: :desc)

# Moving an instance in the rankings (All have ! versions that will
# automatically save and raise an error on failed validations)
page.move_to_top # Move to the top of the rankings
page.move_to_bottom # Move to the bottom of the rankings
page.move_between("H", "M") # Move between two other rankings
page.move_to(4) # Move to the 4th ranking (or bottom if there are less than 4 rows)

page.rank_value # The value that LexoRank is using to rank the row
page.ranked? # Returns true if the instance has a ranking.
```

## Advanced Features

### BYOR (Bring Your Own Ranker)

The ranker of LexoRanker is pretty simple and you can provide your own
ranking solution. When calling `.rankable` in your class, you can pass in
the `ranker:` option with whatever ranker you'd like to use. It needs to
respond to `between(previous_element_rank, next_element_rank)` and will be
used instead of the ranker that is shipped with LexoRanker.

### Character Spaces

The default ranker for LexoRanker can also be customized with a different
character space. This can be passed to LexoRanker with:

`LexoRanker::Ranker.new(characterspace: MyCustomCharacterSpace)`

The character space you pass in will need to respond to:

- `ord(char) # convert a character to an ordinal value`
- `char(ord) # convert an ordinal value to a character`
- `min # the topmost ranking character in your character space`
- `max # the bottommost ranking character in your character space`

#### Notes about Character Spaces

In order to use LexoRank, the database system you use must know how to
lexicographically order the same way Ruby does. For MySQL that is generally
the `ascii_bin` collation for the ranking column. For PostgreSQL, it's the
`C` collation. The character space that is used by default includes
[A-Z, a-z, 0-9] and should be ordered correctly without the collations, however
if you wish to provide your own, you need to adjust your database accordingly.

## Contributing

### Issues

Everyone is welcome to browse the issues and make pull requests. If you need
help, please search the issues to see if there is already one for your
problem. If not, feel free to create a new one.

### Pull Requests

If you see a problem that you can fix, we welcome pull requests. This not
only includes code, but documentation or example usage as well. Here are
some steps to help you get started.

1. Create a Issue for your fix or improvement
2. Fork the repository
3. Create a branch off of `main` for your changes (name it something reasonable)
4. Make your changes (be sure you have tests!)
5. Make sure all specs and the linter run successfully (`rake`)
6. Commit your changes with a reference to your issue number in the commit
   message
7. Push your changes to your fork.
8. Create your pull request.

## Changelog
See CHANGELOG.md

## License

Copyright (c) 2023 PJ Davis (pj.davis@gmail.com)

LexoRanker is released under the [MIT License](https://mit-license.org/).
