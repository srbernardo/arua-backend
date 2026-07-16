class RemoveImagesFromProducts < ActiveRecord::Migration[8.1]
  def change
    remove_column :products, :images, :jsonb
  end
end
