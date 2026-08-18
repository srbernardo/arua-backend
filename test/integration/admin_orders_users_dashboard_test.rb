require "test_helper"

class AdminOrdersUsersDashboardTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    @credentials = { admin: { email: @admin.email, password: "password123" } }
    @category = categories(:top_bikini)
    post "/api/admin/sign_in", params: @credentials, as: :json
    assert_response :success
  end

  def create_order!(user, status: "pending", total: 50.0)
    Order.create!(
      user: user,
      status: status,
      payment_method: "mbway",
      address_street: "Rua Teste 1",
      address_city: "Lisboa",
      address_state: "Lisboa",
      address_zip: "1000-000",
      subtotal: total,
      shipping: 7.99,
      total: total
    )
  end

  def create_user!(name, phone)
    User.create!(name: name, phone: phone)
  end

  # --- Orders ---------------------------------------------------------------

  test "orders index pagina por page e per_page" do
    user = create_user!("Cliente", "911000001")
    5.times { create_order!(user) }

    get "/api/admin/orders", params: { page: 2, per_page: 2 }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body["data"].size
    assert_equal 2, body.dig("meta", "page")
    assert_equal 5, body.dig("meta", "total")
    assert_equal 3, body.dig("meta", "total_pages")
  end

  test "orders index filtra por status" do
    user = create_user!("Cliente", "911000002")
    create_order!(user, status: "pending")
    create_order!(user, status: "delivered")

    get "/api/admin/orders", params: { status: "delivered" }

    body = JSON.parse(response.body)
    assert_equal ["delivered"], body["data"].map { |o| o["status"] }
  end

  test "orders index filtra por status inválido e devolve todos" do
    user = create_user!("Cliente", "911000003")
    create_order!(user, status: "pending")

    get "/api/admin/orders", params: { status: "inexistente" }

    body = JSON.parse(response.body)
    assert_equal ["pending"], body["data"].map { |o| o["status"] }
  end

  test "atualizar status de pedido retorna o resumo atualizado" do
    user = create_user!("Cliente", "911000004")
    order = create_order!(user, status: "pending")

    patch "/api/admin/orders/#{order.id}", params: { order: { status: "confirmed" } }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "confirmed", body["status"]
    assert_equal "confirmed", order.reload.status
  end

  test "atualizar status inválido retorna 422" do
    user = create_user!("Cliente", "911000005")
    order = create_order!(user)

    patch "/api/admin/orders/#{order.id}", params: { order: { status: "invalido" } }, as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].present?
  end

  test "atualizar pedido inexistente retorna 404" do
    patch "/api/admin/orders/999999", params: { order: { status: "confirmed" } }, as: :json

    assert_response :not_found
  end

  test "atualizar pedido sem autenticação retorna 401" do
    user = create_user!("Cliente", "911000006")
    order = create_order!(user)
    delete "/api/admin/sign_out"

    patch "/api/admin/orders/#{order.id}", params: { order: { status: "confirmed" } }, as: :json

    assert_response :unauthorized
  end

  # --- Users ----------------------------------------------------------------

  test "users index pagina e agrega pedidos" do
    user = create_user!("Cliente", "911000007")
    3.times { create_order!(user, total: 20.0) }
    create_user!("Outro", "911000008")

    get "/api/admin/users", params: { page: 1, per_page: 1 }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 1, body["data"].size
    assert_equal 2, body.dig("meta", "total")

    get "/api/admin/users", params: { q: "Cliente" }

    body = JSON.parse(response.body)
    assert_equal 1, body["data"].size
    assert_equal 3, body["data"][0]["orders_count"]
    assert_equal 60.0, body["data"][0]["total_spent"]
  end

  # --- Dashboard ------------------------------------------------------------

  test "dashboard devolve contagens agregadas e stock baixo" do
    user = create_user!("Cliente", "911000009")
    create_order!(user, status: "pending", total: 30.0)
    create_order!(user, status: "delivered", total: 70.0)

    Product.create!(name: "Com Stock Baixo", price: 10.0, category: @category) do |p|
      p.sizes = ["P"]
      p.colors = ["#000000"]
      p.image_colors = {}
      p.variants.build(size: "P", color: "#000000", stock: 2, sku: "SB-P-BK")
    end

    get "/api/admin/dashboard"

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal 2, body.dig("counts", "orders")
    assert_equal 1, body.dig("counts", "pending_orders")
    assert_equal 100.0, body.dig("revenue", "total")
    assert_equal 30.0, body.dig("revenue", "pending")
    assert_equal 1, body.dig("counts", "low_stock_variants")
    assert_equal "Com Stock Baixo", body.dig("low_stock", 0, "name")
    assert_equal 2, body.dig("recent_orders").size
  end

  test "dashboard sem pedidos devolve zeros" do
    get "/api/admin/dashboard"

    body = JSON.parse(response.body)
    assert_equal 0, body.dig("counts", "orders")
    assert_equal 0.0, body.dig("revenue", "total")
    assert_equal [], body.dig("recent_orders")
  end

  # --- Multipart com variantes em JSON (T3.6) -------------------------------

  test "criar produto via multipart com variants e image_colors em JSON" do
    variants = JSON.generate([
      { size: "P", color: "#D4916E", stock: 3, sku: "MJ-P-BR" },
      { size: "M", color: "#D4916E", stock: 5, sku: "MJ-M-BR" }
    ])
    image_colors = JSON.generate({ "#D4916E" => [0] })

    post "/api/admin/products",
         params: {
           product: {
             name: "Multipart JSON",
             price: "39.99",
             category_id: @category.id,
             variants: variants,
             image_colors: image_colors,
             images: [fixture_file_upload("product.png", "image/png")]
           }
         }

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Multipart JSON", body["name"]
    assert_equal 2, body["variants"].size
    assert_equal "MJ-P-BR", body["variants"][0]["sku"]
    assert_equal({ "#D4916E" => [0] }, body["image_colors"])
    assert_equal 1, body["images"].size

    product = Product.find(body["id"])
    assert_equal 2, product.variants.count
    assert product.images.attached?
  end

  test "criar produto via multipart com JSON inválido retorna 422" do
    post "/api/admin/products",
         params: {
           product: {
             name: "JSON Quebrado",
             price: "10.0",
             category_id: @category.id,
             variants: "{nao-e-json"
           }
         }

    assert_response :unprocessable_entity
  end
end