require "rails_helper"

RSpec.describe Game, type: :model do

  it "creates an api key" do
    g = Game.create(title: "Immoral Loot Boxes")
    expect(g.api_keys).to_not be_empty
  end

  describe "player counts" do
    it "defaults to 1-1" do
      game = Game.new
      game.valid?
      expect(game.min_players).to eq 1
      expect(game.max_players).to eq 1
    end

    it "automatically sets max" do
      game = Game.new(min_players: 2)
      game.valid?
      expect(game.max_players).to eq 2
    end

    it "requires max >= min" do
      game = Game.new(min_players: 5, max_players: 2)
      expect(game).to_not be_valid
      expect(game.errors[:max_players]).to_not be_empty
    end

  end

  describe "smart listings" do
    let(:game) do
      g = FactoryBot.build(:game)
      g.tag_list = ["hood", "enterprise", "titan"]
      g
    end

    let!(:matching_playlist) do
      p = FactoryBot.build(:playlist)
      p.smart_tag_list = ["enterprise", "titan"]
      p.save
      p
    end

    let!(:non_matching_playlist) do
      p = FactoryBot.build(:playlist)
      p.smart_tag_list = ["enterprise", "melbourne"]
      p.save
      p
    end

    let!(:dumb_playlist) { FactoryBot.create(:playlist, description: "dumb") }

    it "adds the game to matching playlists" do
      game.save
      expect(game.playlists).to match_array [matching_playlist]
    end

    it "does not add the game to non-matching playlists" do
      game.save
      expect(game.playlists).to_not include(non_matching_playlist)
    end

    it "removes game from playlist if the tags change" do
      game.save
      game.tag_list = ["william", "thomas"]
      game.save

      expect(game.playlists).to_not include(matching_playlist)
    end

    it "retains non-smart playlist listings" do
      game.save
      game.listings.create(playlist: dumb_playlist)
      game.save

      expect(game.playlists).to include(dumb_playlist)
    end
  end

  it "inits with default keymap" do
    game = FactoryBot.create(:game)
    expect(game.key_map).to_not be_nil
    expect(game.key_map.template).to eq "default"
  end

  describe "#published?" do
    it "is true with published_at" do
      game = Game.new(published_at: Time.now)
      expect(game).to be_published
    end

    it "is false without published_at" do
      game = Game.new
      expect(game).to_not be_published
    end
  end

  describe "#launcher_compatible_cover" do
    let(:game) { FactoryBot.create(:game) }
    let(:images) do
      FactoryBot.create_list(:image, 3, parent: game, user: game.users.first)
    end

    it "picks the cover image" do
      game.set_cover(images[1])
      expect(game.launcher_compatible_cover).to eq images[1]
    end

    it "picks the newest non-gif" do
      images[1].update(file_key: "animated.gif")
      game.set_cover(images[1])
      expect(game.launcher_compatible_cover).to eq images[2]
    end
  end

  describe "images" do
    let!(:game) { FactoryBot.create(:game) }

    it "creates a default cover image on game creation" do
      image = game.images.first
      expect(image.file_key).to eq Image::PLACEHOLDERS["Game"]
      expect(image.cover?).to eq true
    end

    it "removes placeholder images when a new image is added" do
      image = Image.create(parent: game, user: game.users.first, file_key: "newpic.png")
      game.reload
      image.reload
      expect(game.images).to eq [image]
      expect(image.cover).to eq true
    end

    it "re-adds the placeholder cover when removing the last image" do
      image = Image.create(parent: game, user: game.users.first, file_key: "newpic.png")
      image.destroy

      game.reload
      expect(game.images.count).to eq 1
      expect(game.images.first.placeholder?).to be true
    end

  end
end