require "rails_helper"

module Sortability
  module ActiveRecord
    module ConnectionAdapters
      RSpec.describe TableDefinition do
        let(:table_definition) { ::ActiveRecord::ConnectionAdapters::TableDefinition.new nil, :test }

        context 'without :on and :null' do
          let(:options) { { something: :else } }

          it '#sortable calls the #integer method, adding defaults' do
            expect(table_definition).to(
              receive(:integer).with(:sort_position, options.merge(null: false))
            )
            table_definition.sortable(**options)
          end
        end

        context 'with :on and :null' do
          let(:options) { { something: :else, on: :pos, null: true } }

          it '#sortable calls the #integer method with the given options' do
            expect(table_definition).to receive(:integer).with(:pos, options.except(:on))
            table_definition.sortable(**options)
          end
        end
      end
    end
  end
end
