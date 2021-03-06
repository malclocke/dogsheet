class UsersController < ApplicationController
  
  skip_before_filter :require_login, :only => [:new, :create] 

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = 'User created'
      redirect_to root_path
    else
      render :action => 'new'
    end
  end

  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      flash[:notice] = 'Profile updated'
      redirect_to root_path
    else
      render :action => 'edit'
    end
  end
end
