$(document).ready(function() {
  $("#guess").focus();

  $("form").submit(function() {
    $.post(
      '/',
      {
        id:    $('#game').val(),
        guess: $('#guess').val()
      },
      function(res, status) {
        css = (res.score > 0) ? "success" : "error"
        $('.guesses').prepend(
          "<li class='" + css + "'>" + res.guess + "</li>"
        );
        $('li:first-child').slideDown(200);
        $("#score").text(res.score);
        $("#guess").val('').focus();
      },
      'json'
    );
  });
});
