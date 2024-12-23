require "rails_helper"

module Sortability
  module ActiveRecord
    RSpec.describe Migration do
      let(:migration) { ::ActiveRecord::Migration.new }
      let(:table)     { :test }

      context 'without some options' do
        let(:options) { { something: :else } }

        it '#add_sortable_column can add a sortable column, adding defaults' do
          expect(migration).to receive(:method_missing).with(
            :add_column, table, :sort_position, :integer, options.merge(null: false)
          )

          migration.add_sortable_column table, **options
        end

        it '#add_sortable_index can add a sortable index, adding defaults' do
          expect(migration).to receive(:method_missing).with(
            :add_index, table, [ :sort_position ], options.merge(unique: true)
          )

          migration.add_sortable_index table, **options
        end
      end

      context 'with all options' do
        let(:options) do
          { something: :else, on: :pos, null: true, unique: false, scope: :container_id }
        end

        it '#add_sortable_column can add a sortable column with the given options' do
          expect(migration).to receive(:method_missing).with(
            :add_column, table, :pos, :integer, options.except(:on)
          )

          migration.add_sortable_column table, **options
        end

        it '#add_sortable_index can add a sortable index with the given options' do
          expect(migration).to receive(:method_missing).with(
            :add_index, table, [ :container_id, :pos ], options.except(:on, :scope)
          )

          migration.add_sortable_index table, **options
        end
      end
    end
  end
end
