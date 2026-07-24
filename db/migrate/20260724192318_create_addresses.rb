class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses do |t|
      t.references :user, null: false, foreign_key: true
      t.string :street, null: false
      t.string :neighborhood
      t.string :city, null: false
      t.string :state, null: false
      t.string :zip, null: false
      t.boolean :default, default: false, null: false

      t.timestamps
    end
  end
end
