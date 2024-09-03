class CreateTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :templates do |t|
      t.string :name
      t.string :basename
      t.string :filetype
      t.text :content

      t.timestamps
    end
  end
end
