require "test_helper"

class Api::V1::AuthenticationTest < ActionDispatch::IntegrationTest
  test "salary data requires a session" do
    get "/api/v1/employees", as: :json

    assert_response :unauthorized
  end

  test "sign in is case insensitive and sign out ends the session" do
    account = HrAccount.create!(name: "Avery Chen", email: "hr@acme.test", password: "Acme-HR-2026")

    post "/api/v1/session", params: { email: "HR@acme.test", password: "wrong-password-1" }, as: :json
    assert_response :unauthorized

    post "/api/v1/session", params: { email: "HR@acme.test", password: "Acme-HR-2026" }, as: :json
    assert_response :success
    assert_equal account.id, response.parsed_body.dig("hr", "id")
    assert response.parsed_body["csrf_token"].present?

    get "/api/v1/employees", as: :json
    assert_response :success

    delete "/api/v1/session", as: :json
    assert_response :no_content

    get "/api/v1/employees", as: :json
    assert_response :unauthorized
  end
end
