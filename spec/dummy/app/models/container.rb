class Container < ApplicationRecord
  sortable_class

  sortable_has_many :items, inverse_of: :container
end
