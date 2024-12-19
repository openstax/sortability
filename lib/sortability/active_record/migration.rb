module Sortability
  module ActiveRecord
    module Migration
      # Adds a non-null sortable column to an existing table (no index)
      def add_sortable_column(table, **options)
        options[:null] = false if options[:null].nil?
        on = options.delete(:on) || :sort_position

        add_column table, on, :integer, **options
      end

      # Adds a unique index covering the sort scope cols in an existing table
      def add_sortable_index(table, **options)
        options[:unique] = true if options[:unique].nil?
        scope = options.delete(:scope)
        on = options.delete(:on) || :sort_position
        columns = ([scope] << on).flatten.compact

        add_index table, columns, **options
      end
    end
  end
end

ActiveRecord::Migration.send :include, Sortability::ActiveRecord::Migration
