class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    create
  end

  private

    def create
      auth_params = request.env["omniauth.auth"]

      unless auth_params.is_a?(OmniAuth::AuthHash)
        auth_params = OmniAuth::AuthHash.new(auth_params)
      end

      provider = AuthenticationProvider.where(name: auth_params.provider).first
      authentication = provider.user_authentications.where(uid: auth_params.uid).first
      if authentication
        sign_in_with_existing_authentication(authentication)
      elsif user_signed_in?
        create_authentication_and_sign_in(auth_params, current_user, provider)
      else
        create_user_and_authentication_and_sign_in(auth_params, provider)
      end
    end

    def sign_in_with_existing_authentication(authentication)
      flash[:notice] = "Welcome back #{authentication.user.email}!"
      sign_in_and_redirect(:user, authentication.user)
    end

    def create_authentication_and_sign_in(auth_params, user, provider)
      UserAuthentication.create_from_omniauth(auth_params, user, provider)
      sign_in_and_redirect(:user, user)
    end

    def create_user_and_authentication_and_sign_in(auth_params, provider)
      user = User.create_from_omniauth(auth_params)
      if user.valid?
        flash[:notice] = "Welcome #{user.email}"
        create_authentication_and_sign_in(auth_params, user, provider)
      else
        flash[:error] = user.errors.full_messages.first
        redirect_to new_user_registration_url
      end
    end
end
