(function(window, $, undefined) {

  csrf_token = $("meta[name='csrf-token']").attr("content");
  game_id = null;

  $(function() {
    $(".open-playlist-modal").click(function() {
      game_id = $(this).attr("data-game-id");
    });

    $(".add-to-playlist a").click(function(e) {
      e.preventDefault();

      var playlist_id = $(this).attr("href");

      console.log("game: " + game_id + ", playlist: " + playlist_id);

      $.ajax({
        type: "POST",
        url:  "/listings",
        data: {
          game_id: game_id,
          playlist_id: playlist_id,
          authenticity_token: csrf_token
        },
        success: function() {
          $(".add-to-playlist a[href='" + playlist_id + "'] span.playlist-check").removeClass("invisible");
        }
      })
    });
  });

})(window, jQuery)

