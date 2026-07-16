categories = [
  { slug: "top-bikini", name: "Top Bikini" },
  { slug: "cueca-bikini", name: "Cueca Bikini" },
  { slug: "bikinis", name: "Bikínis" },
  { slug: "conjunto", name: "Conjunto" },
  { slug: "fatos-banho", name: "Fatos de Banho" },
  { slug: "ver-todos", name: "Ver Todos" }
]

categories.each do |attrs|
  Category.find_or_create_by!(slug: attrs[:slug]) do |c|
    c.name = attrs[:name]
  end
end

products_data = [
  { id: 1,  name: "Classic High-Waisted",  price: 89.99,  category_slug: "top-bikini" },
  { id: 2,  name: "Surf Style Bottom",     price: 69.99,  category_slug: "cueca-bikini" },
  { id: 3,  name: "Lace Detail Set",       price: 119.99, category_slug: "conjunto" },
  { id: 4,  name: "Striped High-Waisted",  price: 79.99,  category_slug: "bikinis" },
  { id: 5,  name: "Tropical Print Bottom", price: 74.99,  category_slug: "cueca-bikini" },
  { id: 6,  name: "Polka Dot Set",         price: 99.99,  category_slug: "conjunto" },
  { id: 7,  name: "Bandeau Top",           price: 59.99,  category_slug: "top-bikini" },
  { id: 8,  name: "Strapless Fit",         price: 84.99,  category_slug: "fatos-banho" },
  { id: 9,  name: "Ribbed Texture Top",    price: 64.99,  category_slug: "top-bikini" },
  { id: 10, name: "High Cut Bottom",       price: 59.99,  category_slug: "cueca-bikini" },
  { id: 11, name: "Wrap Style Set",        price: 109.99, category_slug: "conjunto" },
  { id: 12, name: "Sporty Cut Top",        price: 54.99,  category_slug: "top-bikini" }
]

colors = ["#D4916E", "#F3EBE2", "#C4CFDE"]

products_data.each do |data|
  category = Category.find_by!(slug: data[:category_slug])

  Product.find_or_create_by!(id: data[:id]) do |p|
    p.name = data[:name]
    p.price = data[:price]
    p.category = category
    p.colors = colors
    p.images = [
      "/images/product-#{data[:id]}.png",
      "https://picsum.photos/seed/#{data[:id]}a/320/360",
      "https://picsum.photos/seed/#{data[:id]}b/320/360",
      "https://picsum.photos/seed/#{data[:id]}c/320/360"
    ]
  end
end

puts "Seeded #{Category.count} categories and #{Product.count} products."
