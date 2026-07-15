class Product < ApplicationRecord
  belongs_to :category
  has_many :product_images, -> { order(position: :asc) }, dependent: :destroy

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
end
