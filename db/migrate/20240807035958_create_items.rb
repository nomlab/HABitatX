class CreateItems < ActiveRecord::Migration[7.1]
  def change
    create_table :items do |t|
      t.string :name
      t.json :dsl_info
      t.integer :items_group_id

      t.timestamps
    end
  end
end
