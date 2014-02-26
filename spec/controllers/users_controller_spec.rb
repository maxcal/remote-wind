require 'spec_helper'

describe UsersController do

  let!(:user) do
    user = FactoryGirl.create(:user)
    sign_in user
    user
  end

  describe "GET 'show'" do

    before do
      get :show, id: user.to_param
    end

    it "should be successful" do
      expect(response).to be_success
    end

    it "should find the right user" do
      expect(assigns(:user)) == @user
    end

    it "renders the correct template" do
      expect(response).to render_template :show
    end
  end

  describe "GET 'index'" do

    context "when not authorized" do
      it "should be denied" do
        bypass_rescue
        expect { get 'index' }.to raise_error(CanCan::AccessDenied)
      end
    end

    context "when authorized" do
      before do
        sign_in create(:admin)
      end
      it "should be successful" do
        get 'index'
        expect(response).to be_success
      end
      it "renders the correct template" do
        get :index
        expect(response).to render_template :index
      end
    end
  end
end
