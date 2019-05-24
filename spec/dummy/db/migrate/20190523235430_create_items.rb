class CreateItems < ActiveRecord::Migration[5.2]
  def change
    create_table :items do |t|
      t.references :container, null: false, index: false, foreign_key: true
      t.sortable

      t.timestamps
    end

    add_sortable_index :items, scope: :container_id
  end
end
