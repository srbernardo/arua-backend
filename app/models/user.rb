class User < ApplicationRecord
  has_many :addresses, dependent: :destroy
  has_many :favorites, dependent: :destroy

  validates :name, presence: true
  validates :phone, presence: true, uniqueness: true
  validates :phone, format: { with: /\A\d{9}\z/, message: "must be exactly 9 digits" }

  def self.find_by_phone(phone)
    find_by(phone: phone.delete(" "))
  end
end
