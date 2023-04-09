# PAYPAL-PAYMENT

This is an app to trigger payment through paypal.

Requirements:
```
Ruby version -> 3.1.3
Rails version -> 7.0.4
postgresql
```

### Steps to run:
```
git clone git@github.com:elibiz443/paypal-payment.git
cd paypal-payment
bundle
rails db:create db:migrate db:seed && rails s
localhost:3000(In browser)
```

### The making of the app:

In gemfile, Add:
```
gem 'paypal-checkout-sdk'
gem "bcrypt", "~> 3.1.7"
bundle
```
In config/initializers, Add:
```
#paypal.rb

require "uri"

module PayPalHttp
  class FormEncoded
    def encode(request)
      encoded_params = []
      request.body.each do |k, v|
        encoded_params.push("#{encode_part(k)}=#{encode_part(v)}")
      end

      encoded_params.join("&")
    end

    def decode(body)
      raise UnsupportedEncodingError.new("FormEncoded does not support deserialization")
    end

    def content_type
      /^application\/x-www-form-urlencoded/
    end

    private

    def encode_part(part)
      URI.encode_www_form_component(part.to_s)
    end
  end
end
```
Add models and controllers:
```
rails g model user email password_digest
rails g model order paid:boolean name token price:float currency user_id:bigint

rails g contoller users index create edit
rails g controller orders index payment_confirmation
```

Modify models:
```
#user.rb
has_secure_password
validates :email, presence: true

#order.rb
belongs_to :user
```

Modify controllers:
```
#users_controller.rb
def index
end

def create
  @user = User.new(user_params)

  if @user.save
    flash[:notice] = "User Successfully Created!"
    redirect_to "/"
  else
    flash[:alert] = @user.errors.full_messages.join(', ')
    redirect_to "/"
  end
end

def edit
end

private

def user_params
  params.require(:user).permit(:email, :password)
end

#orders_controller.rb
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
  client_id = 'your_client_id'
  client_secret = 'your_client_secret'
  # Creating an environment
  environment = PayPal::SandboxEnvironment.new client_id, client_secret
  @client = PayPal::PayPalHttpClient.new(environment)
end

def order_params
  params.require(:order).permit(:price, :name, :paid, :token, :currency, :user_id)
end
```

Modify routes to:
```
get 'users/index'
get 'users/create'
get 'users/edit'

get 'orders/index'
get 'orders/create'
get 'orders/capture_order'
get '/', :to => 'orders#index'
post :create_order, :to => 'orders#create_order'
post :capture_order, :to => 'orders#capture_order'
get '/confirmation', :to => 'orders#payment_confirmation'

root "orders#index"
```

Update views to:
```
#application.html.erb
<!DOCTYPE html>
<html>
  <head>
    <title>PaypalPayment</title>
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <%= csrf_meta_tags %>
    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
    <%= javascript_importmap_tags %>

    <!-- Font Awesome -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.1.1/css/all.min.css" integrity="sha512-KfkfwYDsLkIlwQp6LFnl8zNdLGxu9YAA1QvwINks4PhcElQSvqcyVLLD9aMhXd13uQjoXtEKNosOWaZqXgel0g==" crossorigin="anonymous" referrerpolicy="no-referrer" />
    
    <!-- Bootstrap -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/5.1.3/css/bootstrap.min.css" integrity="sha512-GQGU0fMMi238uA+a/bdWJfpUGKUkBdgfFdgBm72SUQ6BeyWjoY/ton0tEjH+OSH9iP4Dfh+7HM0I9f5eR0L/4w==" crossorigin="anonymous" referrerpolicy="no-referrer" />
  </head>

  <body>
    <%= yield %>
  </body>
</html>

#orders/index.html.erb
<div id="smart-button-container">
  <div style="padding: 10px;">
    <% flash.each do |type, msg| %>
      <%= content_tag :div, msg, class: build_alert_classes(type) %>
    <% end %>
  </div>

  <div style="text-align: center; margin-top: 0.625rem;" id="paypal-button-container"></div>

</div>

<script src="https://www.paypal.com/sdk/js?client-id=AQEtm4Pk5EAEp-Qijyem0gVMA-XJW07D9xesRffx2cM_rKXuG2-xeBzRB7LEM5z50N42hlHsTJBZMgYx" data-sdk-integration-source="button-factory"></script>

<script>

  paypal.Buttons({
    style: {
      color: 'blue',
      shape: 'pill',
      label: 'checkout',
      layout: 'vertical',
      
    },
    env: 'sandbox', // Valid values are sandbox and live.

    createOrder: async () => {
      const response = await fetch('/create_order', {method: 'POST'});
      const responseData = await response.json();
      return responseData.token;
    },

    onApprove: async (data) => {
      const response = await fetch('/capture_order', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({order_id: data.orderID})
      });
      const responseData = await response.json();
      if (responseData.status === 'COMPLETED') {
        // Show a success message within this page
        window.location.href='/confirmation';
      }
    }
  }).render('#paypal-button-container');

</script>

#orders/payment_confirmation.html.erb
<h4 style="text-align: center;padding-top: 100px;color: #34495E;font-size: 2.5rem;">Payment Successful!</h4>
<a href="/" style="text-decoration: none;margin: 10px auto 20px 40%;font-size: 1rem;color: #154360;font-weight: bold;border: 2px solid #154360;padding: 10px 20px 10px 20px;">
  Back<b style="visibility: hidden;">_</b>Home
</a>

```

Modify seed.rb to:
```
User.create(
  email: "example@example.com",
  password: "qqqqqq"
)
```

Add alert helper:
```
#helpers/alert_helper.rb

module AlertHelper
  def build_alert_classes(alert_type)
    classes = 'alert alert-dismissable '
    case alert_type.to_sym 
    when :alert, :danger, :error, :validation_errors
      classes += 'alert-danger'
    when :warning, :todo
      classes += 'alert-warning'
    when :notice, :success
      classes += 'alert-success'
    else 
      classes += 'alert-info'
    end
  end
end
```

Run the app:
```
rails db:create db:migrate db:seed && rails s
localhost:3000
```
