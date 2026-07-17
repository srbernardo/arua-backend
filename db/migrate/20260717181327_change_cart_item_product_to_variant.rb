class ChangeCartItemProductToVariant < ActiveRecord::Migration[8.1]
  def change
    remove_reference :cart_items, :product, foreign_key: true
    add_reference :cart_items, :variant, null: false, foreign_key: true
  end
end
