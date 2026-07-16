class Product < ApplicationRecord
  belongs_to :category
  has_many_attached :images

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
