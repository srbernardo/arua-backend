class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  validates :order_number, presence: true, uniqueness: true
  validates :status, presence: true, inclusion: { in: %w[pending confirmed shipped delivered cancelled] }
  validates :payment_method, presence: true, inclusion: { in: %w[mbway dinheiro] }
  validates :address_street, :address_city, :address_state, :address_zip, presence: true
  validates :subtotal, :total, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :recent, -> { where("created_at > ?", 1.hour.ago) }

  before_validation :generate_order_number

  private

  def generate_order_number
    self.order_number = "ORD-#{Nanoid.generate(size: 6)}"
  end
end
