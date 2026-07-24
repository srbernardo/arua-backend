class Address < ApplicationRecord
  belongs_to :user

  validates :street, :city, :state, :zip, presence: true

  scope :ordered, -> { order(default: :desc, created_at: :desc) }

  def make_default!
    user.addresses.update_all(default: false)
    update!(default: true)
  end
end
