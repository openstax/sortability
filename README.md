# Sortability

[![Gem Version](https://badge.fury.io/rb/sortability.svg)](http://badge.fury.io/rb/sortability)
[![Build Status](https://travis-ci.org/openstax/sortability.svg?branch=master)](https://travis-ci.org/openstax/sortability)
[![Code Climate](https://codeclimate.com/github/openstax/sortability.png)](https://codeclimate.com/github/openstax/sortability)

Sortability is a gem that makes it easy to manage records
that can be sorted and reordered by users of your Rails app.

## Installation

Add this line to your application's Gemfile:

```rb
gem 'sortability'
```

And then execute:

```sh
$ bundle install
```

In the following instructions:
- `Record` refers to the model your users are allowed to reorder
- `Container` refers to the model that holds ordered `Record`s (e.g. a list)

### Migrations

Sortability uses a non-null integer column in your `records` table
to store the sort order.
It is also a good idea to have a unique index that covers the sort column
and any `container_id` or `container_type` columns.
By default, the sort column is named `sort_position`, but that name can be
changed by passing the `on` option to the methods provided by this gem.
This will also change the names of the methods created on the `Record` model.
The `scope` option in the following methods specifies the container foreign
key column(s). You can ommit it if the `records` should be sorted globally.

#### Existing Tables

If you don't already have this column, you will need to add it
to the `records` table using a migration:

```sh
$ rails g migration add_sort_position_to_records
```

In this migration, you will want something similar to this:

```rb
class AddSortPositionToRecords < ActiveRecord::Migration
  def change
    add_sortable_column :records # , on: :sort_position
    add_sortable_index :records, scope: :container_id # , on: :sort_position
  end
end
```

#### New Tables

If you haven't created the `records` table yet, you can use the `sortable`
method to create the appropriate column in the new table,
but you should still create the index using `add_sortable_index`
to ensure that the index covers the appropriate column(s):

```rb
class CreateRecords < ActiveRecord::Migration
  def change
    create_table :records do |t|
      t.sortable # on: :sort_position
    end

    add_sortable_index :records, scope: :container_id # , on: :sort_position
  end
end
```

### Models

#### Record

Replace the `belongs_to :container` relation in your `Record` model with:

```rb
sortable_belongs_to :container, inverse_of: :records,
                                scope: :container_id # , on: :sort_position
```

It is highly recommended that you specify the `inverse_of` and `scope` options.

If `records` are sorted globally, without a `container`,
use the `sortable_class` method instead:

```rb
sortable_class # on: :sort_position, scope: :sort_group_number
```

#### Container

Simply replace the `has_many :records` relation in your `Container` model with:

```rb
sortable_has_many :records, inverse_of: :container # , on: :sort_position
```

## Usage

Once you have run the migrations and modified your models according to the installation instructions, you are ready to start sorting the `records`.
Here are some things that you can do:

- Get all the `records` in order directly from the relation in the `container`
  (or from `Record.all` if the `records` are globally sorted).

- Get all peers of a `record` (`records` in the same `container`)
  by using the `sort_position_peers` method.

- Create a new `container` with several `records` with one call to
  `container.save` and have all the records receive valid `sort_position`s.

- Add a new `record` to an existing `container` and have it automatically
  appended at the end of the list.

- Set the `sort_position` for a `record` and have other `records`
  in the same `container` be automatically updated to create a gap
  when that `record` is saved.

- Change a `record`'s `container` and have other `records` in the new
  `container` also be automatically updated to create a gap for that `record`.

- Close all gaps in the `sort_position` for the peers of a `record`
  by calling the `compact_sort_position_peers` method.

- Get the next or previous record by using the `next_by_sort_position` or
  `previous_by_sort_position` methods.

The `sort_position` is not guaranteed to contain consecutive numbers.
When listing the `records`, you should compute their positions
in application code as you iterate through the list.
If you need the position for a single `record`, call
`compact_sort_position_peers` first to close any gaps
in its peers, then read `sort_position` directly.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Write specs for your feature
4. Implement your new feature
5. Test your feature (`rake`)
6. Commit your changes (`git commit -am 'Added some feature'`)
7. Push to the branch (`git push origin my-new-feature`)
8. Create new Pull Request

## Development Environment Setup

1. Use bundler to install all dependencies:

  ```sh
  $ bundle install
  ```

2. Load the schema:

  ```sh
  $ rake db:schema:load
  ```

  Or if the above fails:

  ```sh
  $ bundle exec rake db:schema:load
  ```

## Testing

To run all existing tests for Sortability,
simply execute the following from the main folder:

```sh
$ rake
```

Or if the above fails:

```sh
$ bundle exec rake
```

## License

This gem is distributed under the terms of the MIT license.
See the MIT-LICENSE file for details.
