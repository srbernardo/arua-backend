class ChangeSizeToSizesOnProducts < ActiveRecord::Migration[8.1]
  def change
    remove_column :products, :size, :string
    add_column :products, :sizes, :jsonb, default: []
  end
end
