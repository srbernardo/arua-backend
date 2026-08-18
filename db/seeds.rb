require "open-uri"

categories = [
  { slug: "top-bikini", name: "Top Bikini" },
  { slug: "cueca-bikini", name: "Cueca Bikini" },
  { slug: "bikinis", name: "Bikínis" },
  { slug: "conjunto", name: "Conjunto" },
  { slug: "fatos-banho", name: "Fatos de Banho" }
]

categories.each do |attrs|
  Category.find_or_create_by!(slug: attrs[:slug]) do |c|
    c.name = attrs[:name]
  end
end

products_data = [
  {
    id: 1, name: "Classic High-Waisted", price: 89.99, category_slug: "top-bikini",
    variants: [
      { size: "P", color: "#D4916E", stock: 5, sku: "CHW-P-BR" },
      { size: "M", color: "#D4916E", stock: 8, sku: "CHW-M-BR" },
      { size: "M", color: "#F3EBE2", stock: 4, sku: "CHW-M-BG" },
      { size: "G", color: "#D4916E", stock: 3, sku: "CHW-G-BR" },
    ]
  },
  {
    id: 2, name: "Surf Style Bottom", price: 69.99, category_slug: "cueca-bikini",
    variants: [
      { size: "XS", color: "#D4916E", stock: 6, sku: "SSB-XS-BR" },
      { size: "XS", color: "#F3EBE2", stock: 4, sku: "SSB-XS-BG" },
      { size: "S", color: "#D4916E", stock: 5, sku: "SSB-S-BR" },
      { size: "M", color: "#D4916E", stock: 7, sku: "SSB-M-BR" },
      { size: "M", color: "#F3EBE2", stock: 3, sku: "SSB-M-BG" },
    ]
  },
  {
    id: 3, name: "Lace Detail Set", price: 119.99, category_slug: "conjunto",
    variants: [
      { size: "P", color: "#D4916E", stock: 3, sku: "LDS-P-BR" },
      { size: "P", color: "#C4CFDE", stock: 2, sku: "LDS-P-AZ" },
      { size: "M", color: "#D4916E", stock: 5, sku: "LDS-M-BR" },
      { size: "M", color: "#F3EBE2", stock: 4, sku: "LDS-M-BG" },
      { size: "M", color: "#C4CFDE", stock: 3, sku: "LDS-M-AZ" },
      { size: "G", color: "#D4916E", stock: 2, sku: "LDS-G-BR" },
    ]
  },
  {
    id: 4, name: "Striped High-Waisted", price: 79.99, category_slug: "bikinis",
    variants: [
      { size: "M", color: "#D4916E", stock: 6, sku: "SHW-M-BR" },
      { size: "M", color: "#F3EBE2", stock: 4, sku: "SHW-M-BG" },
      { size: "G", color: "#D4916E", stock: 3, sku: "SHW-G-BR" },
      { size: "GG", color: "#D4916E", stock: 2, sku: "SHW-GG-BR" },
      { size: "GG", color: "#F3EBE2", stock: 2, sku: "SHW-GG-BG" },
    ]
  },
  {
    id: 5, name: "Tropical Print Bottom", price: 74.99, category_slug: "cueca-bikini",
    variants: [
      { size: "P", color: "#F3EBE2", stock: 5, sku: "TPB-P-BG" },
      { size: "P", color: "#C4CFDE", stock: 3, sku: "TPB-P-AZ" },
      { size: "M", color: "#F3EBE2", stock: 6, sku: "TPB-M-BG" },
      { size: "M", color: "#C4CFDE", stock: 4, sku: "TPB-M-AZ" },
    ]
  },
  {
    id: 6, name: "Polka Dot Set", price: 99.99, category_slug: "conjunto",
    variants: [
      { size: "P", color: "#D4916E", stock: 4, sku: "PDS-P-BR" },
      { size: "P", color: "#F3EBE2", stock: 3, sku: "PDS-P-BG" },
      { size: "P", color: "#C4CFDE", stock: 2, sku: "PDS-P-AZ" },
      { size: "M", color: "#D4916E", stock: 5, sku: "PDS-M-BR" },
      { size: "M", color: "#F3EBE2", stock: 4, sku: "PDS-M-BG" },
      { size: "M", color: "#C4CFDE", stock: 3, sku: "PDS-M-AZ" },
      { size: "G", color: "#D4916E", stock: 2, sku: "PDS-G-BR" },
    ]
  },
  {
    id: 7, name: "Bandeau Top", price: 59.99, category_slug: "top-bikini",
    variants: [
      { size: "P", color: "#C4CFDE", stock: 4, sku: "BTP-P-AZ" },
      { size: "M", color: "#C4CFDE", stock: 6, sku: "BTP-M-AZ" },
      { size: "G", color: "#C4CFDE", stock: 3, sku: "BTP-G-AZ" },
    ]
  },
  {
    id: 8, name: "Strapless Fit", price: 84.99, category_slug: "fatos-banho",
    variants: [
      { size: "M", color: "#D4916E", stock: 5, sku: "STF-M-BR" },
      { size: "M", color: "#C4CFDE", stock: 4, sku: "STF-M-AZ" },
      { size: "G", color: "#D4916E", stock: 3, sku: "STF-G-BR" },
      { size: "G", color: "#C4CFDE", stock: 2, sku: "STF-G-AZ" },
    ]
  },
  {
    id: 9, name: "Ribbed Texture Top", price: 64.99, category_slug: "top-bikini",
    variants: [
      { size: "P", color: "#D4916E", stock: 5, sku: "RTT-P-BR" },
      { size: "P", color: "#F3EBE2", stock: 3, sku: "RTT-P-BG" },
      { size: "P", color: "#C4CFDE", stock: 2, sku: "RTT-P-AZ" },
      { size: "M", color: "#D4916E", stock: 6, sku: "RTT-M-BR" },
      { size: "M", color: "#F3EBE2", stock: 4, sku: "RTT-M-BG" },
      { size: "M", color: "#C4CFDE", stock: 3, sku: "RTT-M-AZ" },
      { size: "G", color: "#D4916E", stock: 2, sku: "RTT-G-BR" },
    ]
  },
  {
    id: 10, name: "High Cut Bottom", price: 59.99, category_slug: "cueca-bikini",
    variants: [
      { size: "XS", color: "#F3EBE2", stock: 4, sku: "HCB-XS-BG" },
      { size: "S", color: "#F3EBE2", stock: 5, sku: "HCB-S-BG" },
      { size: "M", color: "#F3EBE2", stock: 6, sku: "HCB-M-BG" },
    ]
  },
  {
    id: 11, name: "Wrap Style Set", price: 109.99, category_slug: "conjunto",
    variants: [
      { size: "P", color: "#D4916E", stock: 3, sku: "WSS-P-BR" },
      { size: "P", color: "#F3EBE2", stock: 2, sku: "WSS-P-BG" },
      { size: "P", color: "#C4CFDE", stock: 2, sku: "WSS-P-AZ" },
      { size: "M", color: "#D4916E", stock: 5, sku: "WSS-M-BR" },
      { size: "M", color: "#F3EBE2", stock: 4, sku: "WSS-M-BG" },
      { size: "M", color: "#C4CFDE", stock: 3, sku: "WSS-M-AZ" },
      { size: "G", color: "#D4916E", stock: 2, sku: "WSS-G-BR" },
    ]
  },
  {
    id: 12, name: "Sporty Cut Top", price: 54.99, category_slug: "top-bikini",
    variants: [
      { size: "P", color: "#D4916E", stock: 5, sku: "SCT-P-BR" },
      { size: "P", color: "#F3EBE2", stock: 3, sku: "SCT-P-BG" },
      { size: "M", color: "#D4916E", stock: 7, sku: "SCT-M-BR" },
      { size: "M", color: "#F3EBE2", stock: 4, sku: "SCT-M-BG" },
    ]
  }
]

image_color_map = {
  1  => ["#D4916E"],
  2  => ["#D4916E", "#F3EBE2"],
  3  => ["#D4916E", "#F3EBE2", "#C4CFDE"],
  4  => ["#D4916E", "#F3EBE2"],
  5  => ["#F3EBE2", "#C4CFDE"],
  6  => ["#D4916E", "#F3EBE2", "#C4CFDE"],
  7  => ["#C4CFDE"],
  8  => ["#D4916E", "#C4CFDE"],
  9  => ["#D4916E", "#F3EBE2", "#C4CFDE"],
  10 => ["#F3EBE2"],
  11 => ["#D4916E", "#F3EBE2", "#C4CFDE"],
  12 => ["#D4916E", "#F3EBE2"],
}

products_data.each do |data|
  category = Category.find_by!(slug: data[:category_slug])
  sizes = data[:variants].map { |v| v[:size] }.uniq
  colors = data[:variants].map { |v| v[:color] }.uniq

  product = Product.find_or_create_by!(id: data[:id]) do |p|
    p.name = data[:name]
    p.price = data[:price]
    p.category = category
    p.colors = colors
    p.sizes = sizes
  end

  # Variants referenced by carts or orders cannot be destroyed (FK).
  # Keep them in place and sync the rest; the same guard the admin API uses.
  referenced_ids = CartItem.pluck(:variant_id) + OrderItem.pluck(:variant_id)
  product.variants.where.not(id: referenced_ids).destroy_all
  data[:variants].each do |v|
    product.variants.find_or_create_by!(size: v[:size], color: v[:color]) do |var|
      var.stock = v[:stock]
      var.sku = v[:sku]
    end
  end

  next if product.images.attached?

  image_colors = Hash.new { |h, k| h[k] = [] }
  image_index = 0
  img_colors = image_color_map[data[:id]]

  img_colors.each_with_index do |color, ci|
    imgs_per_color = ci == img_colors.size - 1 ? (4 - image_index) : (4 / img_colors.size)
    imgs_per_color.times do
      suffix = %w[a b c d][image_index]
      filename = "#{data[:id]}_#{suffix}.jpg"
      url = "https://picsum.photos/seed/#{data[:id]}_#{suffix}/320/360"

      begin
        downloaded = URI.open(url, read_timeout: 5)
        product.images.attach(io: downloaded, filename: filename, content_type: "image/jpeg")
        image_colors[color] << image_index
      rescue => e
        puts "  [warn] Failed to download #{url}: #{e.message}"
      end

      image_index += 1
    end
  end

  product.update(image_colors: image_colors)
end

puts "Seeded #{Category.count} categories, #{Product.count} products, #{Variant.count} variants."

# Products are seeded with explicit ids; make sure the id sequences stay
# ahead of them so future inserts (admin panel) don't collide.
ActiveRecord::Base.connection.reset_pk_sequence!("products")
ActiveRecord::Base.connection.reset_pk_sequence!("variants")

admin_email = "test@test.com"
admin_password = "123456"
admin = Admin.find_or_initialize_by(email: admin_email.to_s.strip.downcase)

if admin.new_record?
  admin.password = admin_password
  admin.save!
else
  admin.update!(password: admin_password)
end
puts "Admin inicial configurado: #{admin.email}"

