class AddUserToCarts < ActiveRecord::Migration[8.1]
  def change
    add_reference :carts, :user, null: true, foreign_key: true, index: { unique: true }
  end
end
