$(document).ready(function() {
  $("#guess").focus();

  $("form").submit(function() {
    $.ajax({
      type: 'POST',
      url:  '/',
      data: {
        id:    $('#game').val(),
        guess: $('#guess').val()
      },
      complete: function(res, status) {
        $('.guesses').prepend("<li class='" + status + "'>" + res.responseText + "</li>")
        $('li:first-child').slideDown(200);
        $("#guess").val("").focus();
      }
    });
  });
});
