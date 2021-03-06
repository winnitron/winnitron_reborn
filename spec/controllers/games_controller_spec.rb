require 'rails_helper'

RSpec.describe GamesController, type: :controller do
  let(:admin) { FactoryBot.create(:admin) }
  let(:user) { FactoryBot.create(:user) }

  describe "GET index" do
    it "assigns published games" do
      FactoryBot.create_list(:game, 3)
      Game.last.update(published_at: nil)
      get :index
      expect(assigns(:theirs).count).to eq 2
      expect(assigns(:theirs)).to match_array Game.published
    end

    it "returns 200 OK" do
      get :index
      expect(response).to have_http_status :ok
    end

    it "sorts by new" do
      FactoryBot.create_list(:game, 3)
      get :index, params: { sort: "new" }
      expect(assigns(:theirs).map(&:id)).to eq Game.published.order(published_at: :desc).map(&:id)
    end

    it "sorts by name" do
      FactoryBot.create_list(:game, 3)
      get :index, params: { sort: "name" }
      expect(assigns(:theirs).map(&:id)).to eq Game.published.order(title: :asc).map(&:id)
    end
  end

  describe "GET show" do
    let (:game) { FactoryBot.create(:game) }

    context "it exists" do
      it "assigns the game" do
        get :show, params: { id: game.slug }
        expect(assigns(:game)).to eq game
      end

      it "returns 200 OK" do
        get :show, params: { id: game.slug }
        expect(response).to have_http_status :ok
      end

      describe "json response" do
        it "doesn't panic without a zip file" do
          game.game_zips.destroy_all
          get :show, params: { id: game.slug, format: "json" }
          expect(response).to have_http_status :ok
        end
      end
    end

    context "it doesn't exist" do
      it "404's" do
        get :show, params: { id: 321 }
        expect(response).to have_http_status 404
      end
    end

  end

  describe "GET new" do

    context "user is signed in" do
      before :each do
        sign_in user
        get :new
      end

      it "returns 200 OK" do
        expect(response).to have_http_status :ok
      end
    end
  end

  describe "GET edit" do
    let(:game) { FactoryBot.create(:game) }

    context "current user is admin" do
      before :each do
        sign_in admin
        get :edit, params: { id: game.slug }
      end

      it "returns 200 OK" do
        expect(response).to have_http_status :ok
      end
    end
  end

  describe "POST create" do
    let(:attributes) do
      {
        title: "Great",
        description: "Okay"
      }
    end

    context "valid attributes" do
      before :each do
        sign_in user
      end

      it "saves the Game" do
        expect {
          post :create, params: { game: attributes }
        }.to change(Game, :count).by 1
      end
    end

    context "bad attributes" do
      before :each do
        sign_in user
      end

      it "does not save the game" do
        expect {
          post :create, params: { game: {} }
        }.to_not change(Game, :count)
      end

      it "renders new" do
        post :create, params: { game: {} }
        expect(response).to render_template(:new)
      end

    end
  end

  describe "PUT update" do
    let(:game) { FactoryBot.create(:game) }

    let(:attributes) do
      {
        title: "Great"
      }
    end

    context "admin user" do
      before :each do
        sign_in admin
      end

      context "valid attributes" do
        it "saves the Game" do
          put :update, params: { id: game.slug, game: attributes }
          expect(game.reload.title).to eq attributes[:title]
        end
      end

      context "bad attributes" do

        it "does not save the game" do
          put :update, params: { id: game.slug, game: { title: "" } }
          expect(Game.find_by(slug: game.slug).title).to eq game.title
        end

        it "renders edit" do
          put :update, params: { id: game.slug, game: { title: "" } }
          expect(response).to render_template(:edit)
        end

      end
    end
  end

  describe "DELETE destroy" do
    let(:game) { FactoryBot.create(:game) }

    context "non-owner" do
      before :each do
        sign_in FactoryBot.create(:user)
      end

      it "does not delete the game" do
        delete :destroy, params: { id: game.slug }
        expect(Game.find_by(slug: game.slug)).to eq game
      end

      it "returns 403" do
        delete :destroy, params: { id: game.slug }
        expect(response).to have_http_status 403
      end
    end

    context "owner" do
      before :each do
        sign_in game.users.first
      end

      it "deletes the game" do
        delete :destroy, params: { id: game.slug }
        expect(Game.where(id: game.slug).count).to eq 0
      end
    end

    context "admin user" do
      before :each do
        sign_in admin
      end

      it "deletes the game" do
        delete :destroy, params: { id: game.slug }
        expect(Game.where(id: game.slug).count).to eq 0
      end
    end

  end


  describe "GET images" do
    let(:game) { FactoryBot.create(:game) }

    it "allows admin user" do
      sign_in admin
      get :images, params: { id: game.slug }
      expect(response).to have_http_status :ok
    end

    it "allows owner" do
      sign_in game.users.first
      get :images, params: { id: game.slug }
      expect(response).to have_http_status :ok
    end

    it "disallows non-owner" do
      sign_in FactoryBot.create(:user)
      get :images, params: { id: game.slug }
      expect(response).to have_http_status :forbidden
    end
  end

  describe "GET zip" do
    let(:game) { FactoryBot.create(:game) }

    it "allows admin user" do
      sign_in admin
      get :zip, params: { id: game.slug }
      expect(response).to have_http_status :ok
    end

    it "allows owner" do
      sign_in game.users.first
      get :zip, params: { id: game.slug }
      expect(response).to have_http_status :ok
    end

    it "disallows non-owner" do
      sign_in FactoryBot.create(:user)
      get :zip, params: { id: game.slug }
      expect(response).to have_http_status :forbidden
    end
  end

  describe "GET executable" do
    let(:game) { FactoryBot.create(:game) }

    it "allows admin user" do
      sign_in admin
      get :executable, params: { id: game.slug }
      expect(response).to have_http_status :ok
    end

    it "allows owner" do
      sign_in game.users.first
      get :executable, params: { id: game.slug }
      expect(response).to have_http_status :ok
    end

    it "disallows non-owner" do
      sign_in FactoryBot.create(:user)
      get :executable, params: { id: game.slug }
      expect(response).to have_http_status :forbidden
    end

    it "redirects to zip if there isn't any upload yet" do
      game.game_zips.destroy_all
      sign_in game.users.first

      get :executable, params: { id: game.slug }
      expect(response).to redirect_to zip_game_path(game.slug)
    end
  end
end
