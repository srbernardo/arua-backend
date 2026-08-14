require "test_helper"

class AdminProductsTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    @credentials = { admin: { email: @admin.email, password: "password123" } }
    @category = categories(:top_bikini)

    post "/api/admin/sign_in", params: @credentials, as: :json
    assert_response :success
  end

  # --- Index / show ----------------------------------------------------------

  test "index lista produtos com variantes e imagens" do
    product = create_product!(name: "Produto Index")

    get "/api/admin/products"

    assert_response :success
    body = JSON.parse(response.body)

    entry = body.find { |p| p["id"] == product.id }
    assert_not_nil entry
    assert_equal "Produto Index", entry["name"]
    assert_equal "P", entry.dig("variants", 0, "size")
    assert_equal "top-bikini", entry.dig("category", "slug")
  end

  test "index filtra por q" do
    create_product!(name: "Camisa Listrada")
    create_product!(name: "Biquíni Tropical")

    get "/api/admin/products", params: { q: "tropical" }

    body = JSON.parse(response.body)
    assert_equal ["Biquíni Tropical"], body.map { |p| p["name"] }
  end

  test "show retorna produto com variantes e imagens" do
    product = Product.create!(name: "Com Imagens", price: 10.0, category: @category)
    product.images.attach(io: fixture_file_upload("product.png", "image/png"), filename: "a.png")

    get "/api/admin/products/#{product.id}"

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Com Imagens", body["name"]
    assert_equal @category.id, body["category_id"]
    assert_equal 1, body["images"].size
    assert_equal "a.png", body.dig("images", 0, "filename")
    assert body.dig("images", 0, "url").present?
  end

  test "show de produto inexistente retorna 404" do
    get "/api/admin/products/999999"

    assert_response :not_found
    assert JSON.parse(response.body)["error"].present?
  end

  # --- Create ----------------------------------------------------------------

  test "criar produto com variantes e cores retorna 201" do
    post "/api/admin/products",
         params: {
           product: {
             name: "Novo Produto",
             price: "59.99",
             category_id: @category.id,
             sizes: ["P", "M"],
             colors: ["#D4916E", "#F3EBE2"],
             image_colors: { "#D4916E" => [0], "#F3EBE2" => [1] },
             variants: [
               { size: "P", color: "#D4916E", stock: 3, sku: "NP-P-BR" },
               { size: "M", color: "#F3EBE2", stock: 5, sku: "NP-M-BG" }
             ]
           }
         },
         as: :json

    assert_response :created
    body = JSON.parse(response.body)

    assert_equal "Novo Produto", body["name"]
    assert_equal 59.99, body["price"]
    assert_equal ["P", "M"], body["sizes"]
    assert_equal ["#D4916E", "#F3EBE2"], body["colors"]
    assert_equal 2, body["variants"].size
    assert_equal "NP-P-BR", body["variants"][0]["sku"]
    assert_equal 3, body["variants"][0]["stock"]
    assert_equal [], body["images"]

    product = Product.find(body["id"])
    assert_equal 2, product.variants.count
  end

  test "criar produto com imagens via multipart retorna 201 com image_colors" do
    post "/api/admin/products",
         params: {
           product: {
             name: "Com Foto",
             price: "19.99",
             category_id: @category.id,
             sizes: ["P"],
             colors: ["#D4916E"],
             image_colors: { "#D4916E" => ["0"] },
             images: [fixture_file_upload("product.png", "image/png")]
           }
         }

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 1, body["images"].size
    assert_equal "product.png", body.dig("images", 0, "filename")
    assert_equal({ "#D4916E" => [0] }, body["image_colors"])

    product = Product.find(body["id"])
    assert product.images.attached?
  end

  test "criar produto com image_colors incompatíveis retorna 422" do
    post "/api/admin/products",
         params: {
           product: {
             name: "Cores Erradas",
             price: "10.0",
             category_id: @category.id,
             colors: ["#D4916E"],
             image_colors: { "#D4916E" => ["1"] },
             images: [fixture_file_upload("product.png", "image/png")]
           }
         }

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].present?
  end

  test "criar produto com variantes duplicadas retorna 422" do
    post "/api/admin/products",
         params: {
           product: {
             name: "Duplicado",
             price: "10.0",
             category_id: @category.id,
             variants: [
               { size: "P", color: "#D4916E", stock: 1 },
               { size: "P", color: "#D4916E", stock: 2 }
             ]
           }
         },
         as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].present?
    assert_equal 0, Product.where(name: "Duplicado").count
  end

  test "criar produto com dados inválidos retorna 422" do
    post "/api/admin/products",
         params: { product: { name: "", price: "", category_id: @category.id } },
         as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].present?
  end

  test "criar produto sem autenticação retorna 401" do
    delete "/api/admin/sign_out"

    post "/api/admin/products",
         params: { product: { name: "X", price: "1.0", category_id: @category.id } },
         as: :json

    assert_response :unauthorized
  end

  # --- Update ----------------------------------------------------------------

  test "atualizar produto cria, altera e remove variantes" do
    product = create_product!
    variant = product.variants.first

    patch "/api/admin/products/#{product.id}",
          params: {
            product: {
              name: "Atualizado",
              price: "99.99",
              sizes: ["M", "G"],
              variants: [
                { id: variant.id, size: "M", color: "#000000", stock: 9, sku: "UP-M-BK" },
                { size: "G", color: "#FFFFFF", stock: 2, sku: "UP-G-WH" }
              ]
            }
          },
          as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal "Atualizado", body["name"]
    assert_equal 99.99, body["price"]
    assert_equal 2, body["variants"].size
    assert_equal variant.id, body["variants"][0]["id"]
    assert_equal "M", body["variants"][0]["size"]
    assert_equal "UP-G-WH", body["variants"][1]["sku"]

    assert_equal 2, product.reload.variants.count
    assert_equal %w[G M], product.reload.variants.map(&:size).sort
    assert_not Variant.exists?(id: variant.id, size: "P")
  end

  test "atualizar produto anexa e remove imagens" do
    product = create_product!
    product.images.attach(io: fixture_file_upload("product.png", "image/png"), filename: "a.png")
    first_image = product.images.first

    patch "/api/admin/products/#{product.id}",
          params: {
            product: {
              name: product.name,
              images: [fixture_file_upload("product.png", "image/png")],
              remove_image_ids: [first_image.id],
              image_colors: { "#D4916E" => ["0"] }
            }
          }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["images"].size
    assert_not_equal first_image.id, body["images"][0]["id"]
    assert_not product.reload.images.attachments.where(id: first_image.id).exists?
  end

  test "atualizar produto inexistente retorna 404" do
    patch "/api/admin/products/999999",
          params: { product: { name: "X" } },
          as: :json

    assert_response :not_found
  end

  test "atualizar produto sem autenticação retorna 401" do
    product = create_product!
    delete "/api/admin/sign_out"

    patch "/api/admin/products/#{product.id}", params: { product: { name: "X" } }, as: :json

    assert_response :unauthorized
  end

  # --- Destroy ---------------------------------------------------------------

  test "eliminar produto sem associações retorna 204" do
    product = create_product!

    delete "/api/admin/products/#{product.id}"

    assert_response :no_content
    assert_not Product.exists?(product.id)
    assert_equal 0, Variant.where(product_id: product.id).count
  end

  test "eliminar produto com variante em carrinho retorna 422" do
    product = create_product!
    cart = Cart.create!(session_id: "sessao-teste")
    CartItem.create!(cart: cart, variant: product.variants.first, quantity: 1)

    delete "/api/admin/products/#{product.id}"

    assert_response :unprocessable_entity
    assert Product.exists?(product.id)
  end

  test "eliminar produto sem autenticação retorna 401" do
    product = create_product!
    delete "/api/admin/sign_out"

    delete "/api/admin/products/#{product.id}"

    assert_response :unauthorized
    assert Product.exists?(product.id)
  end

  private

  def create_product!(name: "Produto Teste")
    Product.create!(name: name, price: 25.0, category: @category) do |p|
      p.sizes = ["P"]
      p.colors = ["#D4916E"]
      p.variants.build(size: "P", color: "#D4916E", stock: 4, sku: "PT-P-BR")
      p.image_colors = {}
    end
  end
end
