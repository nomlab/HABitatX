class CreateItemsGroups < ActiveRecord::Migration[7.1]
  def change
    create_table :items_groups do |t|
      t.string :name
      t.integer :template_id

      t.timestamps
    end
  end
end