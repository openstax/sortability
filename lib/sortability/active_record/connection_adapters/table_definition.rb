module Sortability
  module ActiveRecord
    module ConnectionAdapters
      module TableDefinition
        # Adds a non-null sortable column on table creation (no index)
        def sortable(options = {})
          options[:null] = false if options[:null].nil?
          on = options.delete(:on) || :sort_position

          integer on, options
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::TableDefinition.send(
  :include, Sortability::ActiveRecord::ConnectionAdapters::TableDefinition)
