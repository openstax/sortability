class Item < ApplicationRecord
  sortable_belongs_to :container, inverse_of: :items
end
