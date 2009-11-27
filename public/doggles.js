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
        if( res.result == "success" ) {
          list = "success"
          item = "success"
        } else if( res.result == "dupe" ) {
          list = "error"
          item = "dupe"
        } else {
          list = "error"
          item = "error"
        }

        $("." + list + "-list").prepend(
          "<li class='" + item + "'>" + res.guess + "</li>"
        );
        $('.' + list + '-list li:first-child').slideDown();
        $("#score").text(res.score);
        $("#guess").val('').focus();
      },
      'json'
    );
  });
});
