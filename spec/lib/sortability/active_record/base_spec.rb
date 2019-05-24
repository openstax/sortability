require "rails_helper"

module Sortability
  module ActiveRecord
    RSpec.describe Base do
      context 'unscoped' do
        let(:container_1) { Container.new }
        let(:container_2) { Container.new }

        it 'can return the sort peers for a record' do
          expect(container_1.sort_position_peers).to be_empty
          expect(container_2.sort_position_peers).to be_empty

          container_1.save!
          expect(container_1.sort_position_peers).to eq [ container_1 ]
          expect(container_2.sort_position_peers).to eq [ container_1 ]

          container_2.save!
          expect(container_1.sort_position_peers).to eq [ container_1, container_2 ]
          expect(container_2.sort_position_peers).to eq [ container_1, container_2 ]
        end

        it 'automatically assigns sequential sort_positions to created records' do
          expect(container_1.sort_position).to be_nil
          expect(container_2.sort_position).to be_nil

          container_1.save!
          expect(container_1.sort_position).to eq 1
          expect(container_2.sort_position).to be_nil

          container_2.save!
          expect(container_1.sort_position).to eq 1
          expect(container_2.sort_position).to eq 2
        end

        it "automatically increases other records' sort_positions to avoid conflicts" do
          container_1.save!
          container_2.save!
          container_3 = Container.create! sort_position: 1

          expect(container_1.reload.sort_position).to eq 2
          expect(container_2.reload.sort_position).to eq 3
          expect(container_3.sort_position).to eq 1
          expect(container_3.reload.sort_position).to eq 1
        end

        it 'can return the next record by sort_position' do
          container_1.save!
          container_2.save!

          expect(container_1.next_by_sort_position).to eq container_2
          expect(container_2.next_by_sort_position).to be_nil
        end

        it 'can return the previous record by sort_position' do
          container_1.save!
          container_2.save!

          expect(container_1.previous_by_sort_position).to be_nil
          expect(container_2.previous_by_sort_position).to eq container_1
        end

        it 'can compact the sort peers to make their numbers sequential' do
          container_1.sort_position = 21
          container_1.save!
          container_2.sort_position = 42
          container_2.save!

          expect(container_1.reload.sort_position).to eq 21
          expect(container_2.reload.sort_position).to eq 42

          container_1.compact_sort_position_peers!

          expect(container_1.sort_position).to eq 1
          expect(container_1.reload.sort_position).to eq 1
          expect(container_2.reload.sort_position).to eq 2

          container_2.compact_sort_position_peers!

          expect(container_1.reload.sort_position).to eq 1
          expect(container_2.sort_position).to eq 2
          expect(container_2.reload.sort_position).to eq 2
        end
      end

      context 'scoped' do
        let(:container_1) { Container.create }
        let(:container_2) { Container.create }
        let(:item_1)      { Item.new(container: container_1) }
        let(:item_2)      { Item.new(container: container_1) }
        let(:item_3)      { Item.new(container: container_2) }

        it 'can return the sort peers for a record' do
          expect(item_1.sort_position_peers).to be_empty
          expect(item_2.sort_position_peers).to be_empty
          expect(item_3.sort_position_peers).to be_empty

          item_1.save!
          expect(item_1.sort_position_peers).to eq [ item_1 ]
          expect(item_2.sort_position_peers).to eq [ item_1 ]
          expect(item_3.sort_position_peers).to be_empty

          container_1.reload
          container_2.reload

          item_2.save!
          expect(item_1.sort_position_peers).to eq [ item_1, item_2 ]
          expect(item_2.sort_position_peers).to eq [ item_1, item_2 ]
          expect(item_3.sort_position_peers).to be_empty

          container_1.reload
          container_2.reload

          item_3.save!
          expect(item_1.sort_position_peers).to eq [ item_1, item_2 ]
          expect(item_2.sort_position_peers).to eq [ item_1, item_2 ]
          expect(item_3.sort_position_peers).to eq [ item_3 ]
        end

        it 'automatically assigns sequential sort_positions to created records in each scope' do
          expect(item_1.sort_position).to be_nil
          expect(item_2.sort_position).to be_nil
          expect(item_3.sort_position).to be_nil

          item_1.save!
          expect(item_1.sort_position).to eq 1
          expect(item_2.sort_position).to be_nil
          expect(item_3.sort_position).to be_nil

          item_2.save!
          expect(item_1.sort_position).to eq 1
          expect(item_2.sort_position).to eq 2
          expect(item_3.sort_position).to be_nil

          item_3.save!
          expect(item_1.sort_position).to eq 1
          expect(item_2.sort_position).to eq 2
          expect(item_3.sort_position).to eq 1
        end

        it "automatically increases other records' sort_positions to avoid conflicts" do
          item_1.save!
          item_2.save!
          item_3.save!
          item_4 = Item.create! container: container_1, sort_position: 1

          expect(item_1.reload.sort_position).to eq 2
          expect(item_2.reload.sort_position).to eq 3
          expect(item_3.reload.sort_position).to eq 1
          expect(item_4.sort_position).to eq 1
          expect(item_4.reload.sort_position).to eq 1
        end

        it 'can return the next record by sort_position' do
          item_1.save!
          item_2.save!
          item_3.save!

          expect(item_1.next_by_sort_position).to eq item_2
          expect(item_2.next_by_sort_position).to be_nil
          expect(item_3.next_by_sort_position).to be_nil
        end

        it 'can return the previous record by sort_position' do
          item_1.save!
          item_2.save!
          item_3.save!

          expect(item_1.previous_by_sort_position).to be_nil
          expect(item_2.previous_by_sort_position).to eq item_1
          expect(item_3.previous_by_sort_position).to be_nil
        end

        it 'can compact the sort peers to make their numbers sequential' do
          item_1.sort_position = 21
          item_1.save!
          item_2.sort_position = 42
          item_2.save!
          item_3.sort_position = 84
          item_3.save!

          expect(item_1.reload.sort_position).to eq 21
          expect(item_2.reload.sort_position).to eq 42
          expect(item_3.reload.sort_position).to eq 84

          item_1.compact_sort_position_peers!

          expect(item_1.sort_position).to eq 1
          expect(item_1.reload.sort_position).to eq 1
          expect(item_2.reload.sort_position).to eq 2
          expect(item_3.reload.sort_position).to eq 84

          item_2.compact_sort_position_peers!

          expect(item_1.reload.sort_position).to eq 1
          expect(item_2.sort_position).to eq 2
          expect(item_2.reload.sort_position).to eq 2
          expect(item_3.reload.sort_position).to eq 84

          item_3.compact_sort_position_peers!

          expect(item_1.reload.sort_position).to eq 1
          expect(item_2.reload.sort_position).to eq 2
          expect(item_3.sort_position).to eq 1
          expect(item_3.reload.sort_position).to eq 1
        end
      end
    end
  end
end
