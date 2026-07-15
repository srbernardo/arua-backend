class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :price
      t.references :category, null: false, foreign_key: true
      t.jsonb :colors, default: []

      t.timestamps
    end
  end
end
