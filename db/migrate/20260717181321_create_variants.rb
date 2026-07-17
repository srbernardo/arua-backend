class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants do |t|
      t.references :product, null: false, foreign_key: true
      t.string :size, null: false
      t.string :color, null: false
      t.integer :stock, default: 0, null: false
      t.string :sku
      t.timestamps
    end

    add_index :variants, [:product_id, :size, :color], unique: true
  end
end
