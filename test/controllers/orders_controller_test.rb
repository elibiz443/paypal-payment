require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get orders_index_url
    assert_response :success
  end

  test "should get payment_confirmation" do
    get orders_payment_confirmation_url
    assert_response :success
  end
end
