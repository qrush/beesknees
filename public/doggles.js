$(document).ready(function() {
  $("form").submit(function() {
    $.ajax({
      type: 'POST',
      url:  '/',
      data: {
        game:  $('#game').val(),
        guess: $('#guess').val()
      },
      complete: function(res, status) {
        console.log(res);
        console.log(status);
      }
    });
  });
});
