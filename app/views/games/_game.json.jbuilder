json.title           game.title
json.slug            game.title.parameterize
json.min_players     game.min_players
json.max_players     game.max_players
json.description     game.description
json.legacy_controls game.legacy_controls
json.download_url    game.download_url
json.last_modified   game.current_zip&.file_last_modified&.iso8601
json.executable      game.current_zip&.executable