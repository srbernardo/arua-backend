class ProductImage < ApplicationRecord
  belongs_to :product

  validates :url, presence: true
  validates :position, presence: true, numericality: { only_integer: true }
end
