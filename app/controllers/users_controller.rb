class UsersController < ApplicationController
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
end
