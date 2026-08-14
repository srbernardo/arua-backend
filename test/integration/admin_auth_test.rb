require "test_helper"

class AdminAuthTest < ActionDispatch::IntegrationTest
  setup do
    @admin = admins(:one)
    @credentials = { admin: { email: @admin.email, password: "password123" } }
  end

  test "login correto retorna o admin e cria sessão" do
    post "/api/admin/sign_in", params: @credentials, as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal @admin.email, body.dig("admin", "email")
    assert_nil body["admin"]["password"]
    assert_nil body["admin"]["encrypted_password"]
    assert_not_nil body["csrf_token"]
    assert_not_nil cookies["_arua_admin_session"]
  end

  test "login com senha errada retorna 401" do
    post "/api/admin/sign_in",
         params: { admin: { email: @admin.email, password: "senha-errada" } },
         as: :json

    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert body["error"].present?

    get "/api/admin/dashboard"
    assert_response :unauthorized
  end

  test "login com email inexistente retorna 401" do
    post "/api/admin/sign_in",
         params: { admin: { email: "nao-existe@arua.test", password: "password123" } },
         as: :json

    assert_response :unauthorized
  end

  test "endpoint protegido sem sessão retorna 401" do
    get "/api/admin/products"
    assert_response :unauthorized

    get "/api/admin/orders"
    assert_response :unauthorized

    get "/api/admin/categories"
    assert_response :unauthorized

    get "/api/admin/users"
    assert_response :unauthorized

    get "/api/admin/dashboard"
    assert_response :unauthorized
  end

  test "endpoint protegido com sessão válida retorna sucesso" do
    post "/api/admin/sign_in", params: @credentials, as: :json
    assert_response :success

    get "/api/admin/products"
    assert_response :success

    get "/api/admin/orders"
    assert_response :success

    get "/api/admin/categories"
    assert_response :success

    get "/api/admin/users"
    assert_response :success

    get "/api/admin/dashboard"
    assert_response :success
  end

  test "logout encerra a sessão e invalida o acesso" do
    post "/api/admin/sign_in", params: @credentials, as: :json
    assert_response :success

    delete "/api/admin/sign_out"
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal true, body["signed_out"]

    get "/api/admin/dashboard"
    assert_response :unauthorized
  end

  test "sessão é invalidada após logout (me retorna 401)" do
    post "/api/admin/sign_in", params: @credentials, as: :json
    delete "/api/admin/sign_out"

    get "/api/admin/me"
    assert_response :unauthorized
  end

  test "/api/admin/me autenticado retorna o admin" do
    post "/api/admin/sign_in", params: @credentials, as: :json

    get "/api/admin/me"
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal @admin.email, body.dig("admin", "email")
    assert_not_nil body["csrf_token"]
  end

  test "/api/admin/me sem autenticação retorna 401" do
    get "/api/admin/me"
    assert_response :unauthorized
  end

  test "utilizador comum (não admin) não consegue aceder endpoints admin" do
    post "/api/admin/sign_in",
         params: { admin: { email: "cliente@arua.test", password: "qualquer-senha" } },
         as: :json
    assert_response :unauthorized

    get "/api/admin/dashboard"
    assert_response :unauthorized
  end

  test "endpoints públicos continuam acessíveis sem sessão" do
    get "/api/categories"
    assert_response :success

    get "/api/products"
    assert_response :success
  end

  # --- Admin categories CRUD -------------------------------------------------

  test "criar categoria autenticado retorna 201" do
    post "/api/admin/sign_in", params: @credentials, as: :json

    post "/api/admin/categories",
         params: { category: { name: "Novo Modelo", slug: "novo-modelo" } },
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Novo Modelo", body["name"]
    assert_equal "novo-modelo", body["slug"]
    assert_equal 0, body["product_count"]
  end

  test "criar categoria sem autenticação retorna 401" do
    post "/api/admin/categories",
         params: { category: { name: "Novo Modelo", slug: "novo-modelo" } },
         as: :json

    assert_response :unauthorized
  end

  test "criar categoria com dados inválidos retorna 422" do
    post "/api/admin/sign_in", params: @credentials, as: :json

    post "/api/admin/categories",
         params: { category: { name: "", slug: "" } },
         as: :json

    assert_response :unprocessable_entity
    assert JSON.parse(response.body)["errors"].present?
  end

  test "atualizar categoria autenticado retorna a categoria atualizada" do
    category = categories(:top_bikini)
    post "/api/admin/sign_in", params: @credentials, as: :json

    patch "/api/admin/categories/#{category.slug}",
          params: { category: { name: "Top Bikini Atualizado" } },
          as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Top Bikini Atualizado", body["name"]
    assert_equal category.slug, body["slug"]
  end

  test "atualizar categoria inexistente retorna 404" do
    post "/api/admin/sign_in", params: @credentials, as: :json

    patch "/api/admin/categories/nao-existe",
          params: { category: { name: "X" } },
          as: :json

    assert_response :not_found
  end

  test "eliminar categoria sem produtos retorna 204" do
    category = categories(:empty_category)
    post "/api/admin/sign_in", params: @credentials, as: :json

    delete "/api/admin/categories/#{category.slug}"

    assert_response :no_content
    assert_not Category.exists?(category.id)
  end

  test "eliminar categoria com produtos retorna 422" do
    category = categories(:top_bikini)
    Product.create!(name: "Produto Teste", price: 10.0, category: category)
    post "/api/admin/sign_in", params: @credentials, as: :json

    delete "/api/admin/categories/#{category.slug}"

    assert_response :unprocessable_entity
    assert Category.exists?(category.id)
  end

  test "eliminar categoria sem autenticação retorna 401" do
    category = categories(:empty_category)

    delete "/api/admin/categories/#{category.slug}"

    assert_response :unauthorized
    assert Category.exists?(category.id)
  end
end
