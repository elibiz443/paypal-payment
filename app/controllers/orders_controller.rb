class OrdersController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :paypal_init, :except => [:index]

  def index; end

  def create_order
    # Construct a request object and set desired parameters
    # Here, OrdersCreateRequest::new creates a POST request to /v2/checkout/orders
    price = '100.00'
    request = PayPalCheckoutSdk::Orders::OrdersCreateRequest::new
    request.request_body({
      intent: "CAPTURE",
      purchase_units: [
        {
          amount: {
            currency_code: "USD",
            value: price
          }
        }
      ]
    })
    begin
      # Call API with your client and get a response for your call
      response = @client.execute(request)
      # If call returns body in response, you can get the deserialized version from the result attribute of the response
      @order = Order.new
      @order.price = price.to_f
      @order.token = response.result.id
      @order.user_id = 1
      @order.name = "Plan1"
      @order.currency = "USD"
      if @order.save
        return render :json => {:token => response.result.id}, :status => :ok
      end
    rescue PayPalHttp::HttpError => ioe
      # Something went wrong server-side
      puts ioe.status_code
      puts ioe.headers["debug_id"]
    end
  end

  def capture_order
    # Here, OrdersCaptureRequest::new() creates a POST request to /v2/checkout/orders
    # order.id gives the orderId of the order created above
    request = PayPalCheckoutSdk::Orders::OrdersCaptureRequest::new params[:order_id]

    begin
      # Call API with your client and get a response for your call
      response = @client.execute(request) 
      
      # If call returns body in response, you can get the deserialized version from the result attribute of the response
      @order = Order.find_by :token => params[:order_id]
      @order.paid = response.result.status == 'COMPLETED'
      if @order.save
        return render :json => {:status => response.result.status}, :status => :ok
      end
    rescue PayPalHttp::HttpError => ioe
      # Something went wrong server-side
      puts ioe.status_code
      puts ioe.headers["paypal-debug-id"]
    end
  end

  private

  def paypal_init
    # Creating Access Token for Sandbox
    client_id = 'AQEtm4Pk5EAEp-Qijyem0gVMA-XJW07D9xesRffx2cM_rKXuG2-xeBzRB7LEM5z50N42hlHsTJBZMgYx'
    client_secret = 'ENWFFPsuTydBlYd0MmH0dk5qCZVgkwToLTGLNyo3CkrprZTarKdiNO6QfmkWfQtVEbq6dbthHvzqO-uq'
    # Creating an environment
    environment = PayPal::SandboxEnvironment.new client_id, client_secret
    @client = PayPal::PayPalHttpClient.new(environment)
  end

  def order_params
    params.require(:order).permit(:price, :name, :paid, :token, :currency, :user_id)
  end
end
