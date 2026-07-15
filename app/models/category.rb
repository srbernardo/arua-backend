class Category < ApplicationRecord
  has_many :products, dependent: :destroy

  validates :slug, presence: true, uniqueness: true
  validates :name, presence: true
end
