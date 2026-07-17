class AddImageColorsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :image_colors, :jsonb, default: []
  end
end
