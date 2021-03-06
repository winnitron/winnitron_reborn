require 'rails_helper'

RSpec.describe PlaylistsController, type: :controller do
  describe "GET index" do
    it_behaves_like "simple GET action", :index

    it "does not list empty playlists" do
      empty_playlist = FactoryBot.create(:playlist)
      playlist = FactoryBot.create(:playlist)
      Listing.create(playlist: playlist, game: FactoryBot.create(:game))

      get :index
      expect(assigns(:theirs)).to match_array [playlist]
    end
  end

  describe "GET show" do
    it_behaves_like "simple GET action", :show do
      let(:params) do
        { id: FactoryBot.create(:playlist).slug }
      end
    end
  end

  describe "GET new" do

    it_behaves_like "requires sign in", :new

    context "user is logged in" do
      let(:user) { FactoryBot.create(:user) }

      before :each do
        sign_in user
      end

      it_behaves_like "simple GET action", :new
    end

  end

  describe "GET edit" do
    it_behaves_like "requires sign in", :edit do
      let(:params) do
        { id: FactoryBot.create(:playlist).slug }
      end
    end

    context "user is signed in" do
      let(:user) { FactoryBot.create(:user) }

      before :each do
        sign_in user
      end

      context "user owns the playlist" do
        let(:playlist) { FactoryBot.create(:playlist, user: user) }
        let(:params) { { id: playlist.slug } }

        it_behaves_like "simple GET action", :edit
      end

      context "user does not own the playlist" do
        context "user is admin" do
          let(:user) { FactoryBot.create(:admin) }

          let(:playlist) { FactoryBot.create(:playlist) }
          let(:params) { { id: playlist.slug } }

          it_behaves_like "simple GET action", :edit
        end

        context "user is not admin" do
          let(:playlist) { FactoryBot.create(:playlist) }

          it "responds 403" do
            get :edit, params: { id: playlist.slug }
            expect(response).to have_http_status :forbidden
          end
        end
      end
    end
  end

  describe "POST create" do
    let(:attributes) do
      {
        title: "Serious Faves"
      }
    end

    let(:user) { FactoryBot.create(:user) }

    it "requires sign in"

    context "valid attributes" do
      before :each do
        sign_in user
      end

      it "saves the playlist" do
        expect {
          post :create, params: { playlist: attributes }
        }.to change(Playlist, :count).by 1
      end

      it "assins ownership to the logged-in user" do
        post :create, params: { playlist: attributes }
        expect(Playlist.last.user).to eq user
      end
    end

    context "bad attributes" do
      let(:bad_attrs) { { garbage_in: "garbage out" } }
      before :each do
        sign_in user
      end

      it "does not save the playlist" do
         expect {
          post :create, params: { playlist: bad_attrs }
        }.to_not change(Playlist, :count)
      end

      it "renders new" do
        post :create, params: { playlist: bad_attrs }
        expect(response).to render_template(:new)
      end
    end
  end

  describe "PUT update" do
    let(:playlist) { FactoryBot.create(:playlist) }

    let(:attributes) do
      {
        title: "Great"
      }
    end

    it "requires sign in"

    context "signed-in" do

      context "user is admin or owns the playlist" do

        let(:admin) { FactoryBot.create(:admin) }
        let(:owner) { playlist.user }

        context "valid attributes" do
          it "saves the playlist" do
            [admin, owner].each do |user|
              sign_in user

              put :update, params: { id: playlist.slug, playlist: attributes }
              expect(playlist.reload.title).to eq attributes[:title]
            end
          end
        end

      end

      context "user does not own the playlist" do
        let(:user) { FactoryBot.create(:user) }

        before :each do
          sign_in user
        end

        it "responds 403" do
          put :update, params: { id: playlist.slug, playlist: attributes }
          expect(response).to have_http_status :forbidden
        end
      end


      context "bad attributes" do
        before :each do
          sign_in playlist.user
        end

        it "does not save the playlist" do
          put :update, params: { id: playlist.slug, playlist: { title: "" } }
          expect(Playlist.find_by(slug: playlist.slug).title).to eq playlist.title
        end

        it "renders edit" do
          put :update, params: { id: playlist.slug, playlist: { title: "" } }
          expect(response).to render_template(:edit)
        end

      end

    end
  end

  describe "DELETE destroy" do
    let!(:playlist) { FactoryBot.create(:playlist) }


    it "requires sign in"

    context "signed in" do
      let(:admin) { FactoryBot.create(:admin) }
      let(:owner) { playlist.user }

      before :each do
        sign_in user
      end

      context "user is admin" do
        let(:user) { admin }

        it "redirects to playlist index" do
          delete :destroy, params: { id: playlist.slug }
          expect(response).to redirect_to(playlists_path)
        end

        it "removes the playlist" do
          delete :destroy, params: { id: playlist.slug }
          expect {
            Playlist.find(playlist.slug)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end

      end

      context "user is owner" do
        let(:user) { owner }

        it "redirects to playlist index" do
          delete :destroy, params: { id: playlist.slug }
          expect(response).to redirect_to(playlists_path)
        end

        it "removes the playlist" do
          delete :destroy, params: { id: playlist.slug }
          expect {
            Playlist.find(playlist.slug)
          }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end

      context "user is not owner" do
        let(:user) { FactoryBot.create(:user) }

        it "does not remove the playlist" do
          expect {
            delete :destroy, params: { id: playlist.slug }
          }.to_not change(Playlist, :count)
        end
      end
    end

  end


end