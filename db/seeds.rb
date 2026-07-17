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
  { id: 1,  name: "Classic High-Waisted",  price: 89.99,  category_slug: "top-bikini", size: "M" },
  { id: 2,  name: "Surf Style Bottom",     price: 69.99,  category_slug: "cueca-bikini", size: "XS" },
  { id: 3,  name: "Lace Detail Set",       price: 119.99, category_slug: "conjunto", size: "L" },
  { id: 4,  name: "Striped High-Waisted",  price: 79.99,  category_slug: "bikinis", size: "XL" },
  { id: 5,  name: "Tropical Print Bottom", price: 74.99,  category_slug: "cueca-bikini", size: "Tamanho Único" },
  { id: 6,  name: "Polka Dot Set",         price: 99.99,  category_slug: "conjunto", size: "S" },
  { id: 7,  name: "Bandeau Top",           price: 59.99,  category_slug: "top-bikini", size: "M" },
  { id: 8,  name: "Strapless Fit",         price: 84.99,  category_slug: "fatos-banho", size: "L" },
  { id: 9,  name: "Ribbed Texture Top",    price: 64.99,  category_slug: "top-bikini", size: "S" },
  { id: 10, name: "High Cut Bottom",       price: 59.99,  category_slug: "cueca-bikini", size: "XS" },
  { id: 11, name: "Wrap Style Set",        price: 109.99, category_slug: "conjunto", size: "M" },
  { id: 12, name: "Sporty Cut Top",        price: 54.99,  category_slug: "top-bikini", size: "M" }
]

product_colors = {
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
  colors = product_colors[data[:id]]

  product = Product.find_or_create_by!(id: data[:id]) do |p|
    p.name = data[:name]
    p.price = data[:price]
    p.category = category
    p.colors = colors
    p.size = data[:size]
  end

  next if product.images.attached?

  image_colors = Hash.new { |h, k| h[k] = [] }
  image_index = 0

  colors.each_with_index do |color, ci|
    imgs_per_color = ci == colors.size - 1 ? (4 - image_index) : (4 / colors.size)
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

puts "Seeded #{Category.count} categories and #{Product.count} products."
