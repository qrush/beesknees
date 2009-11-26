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
        css = res.correct ? "success" : "error"
        $("." + css + "-list").prepend(
          "<li class='" + css + "'>" + res.guess + "</li>"
        );
        $('li:first-child').fadeIn();
        $("#score").text(res.score);
        $("#guess").val('').focus();
      },
      'json'
    );
  });
});
