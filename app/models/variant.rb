class Variant < ApplicationRecord
  belongs_to :product

  validates :size, presence: true
  validates :color, presence: true
  validates :stock, numericality: { greater_than_or_equal_to: 0 }
end
