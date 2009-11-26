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
        if(status == 'success') {
          $('.guesses').prepend("<li class='right'>" + res.responseText + "</li>");
        } else {
          $('.guesses').prepend("<li class='wrong'>" + res.responseText + "</li>");
        }
        $("#guess").val("").focus();
      }
    });
  });
});
