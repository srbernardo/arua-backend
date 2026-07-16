class Product < ApplicationRecord
  belongs_to :category

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
