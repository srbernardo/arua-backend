class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user, null: false, foreign_key: true
      t.string :order_number, null: false
      t.string :status, null: false, default: "pending"
      t.string :payment_method, null: false
      t.string :address_street, null: false
      t.string :address_neighborhood
      t.string :address_city, null: false
      t.string :address_state, null: false
      t.string :address_zip, null: false
      t.decimal :subtotal, precision: 10, scale: 2, null: false
      t.decimal :shipping, precision: 10, scale: 2, null: false, default: 7.99
      t.decimal :total, precision: 10, scale: 2, null: false

      t.timestamps
    end

    add_index :orders, :order_number, unique: true
    add_index :orders, [:user_id, :created_at]
  end
end
