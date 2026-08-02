class Cart < ApplicationRecord
  belongs_to :user, optional: true

  has_many :cart_items, dependent: :destroy

  validates :session_id, presence: true, uniqueness: true
end
