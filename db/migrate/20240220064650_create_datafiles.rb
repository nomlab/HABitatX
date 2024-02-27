class CreateDatafiles < ActiveRecord::Migration[7.1]
  def change
    create_table :datafiles do |t|
      t.string :title_datafile
      t.json :table
      t.integer :template_id
      t.timestamps
    end
  end
end