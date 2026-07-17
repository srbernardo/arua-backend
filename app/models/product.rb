class Product < ApplicationRecord
  belongs_to :category
  has_many_attached :images

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than: 0 }
  validate :image_colors_must_cover_all_images, if: -> { image_colors.is_a?(Hash) }

  private

  def image_colors_must_cover_all_images
    return unless images.attached?

    all_indices = image_colors.values.flatten.sort.uniq
    expected = (0...images.size).to_a
    unless all_indices == expected
      errors.add(:image_colors, "must include all image indices")
    end

    if image_colors.keys.any?(&:blank?)
      errors.add(:image_colors, "cannot contain blank color keys")
    end
  end
end
