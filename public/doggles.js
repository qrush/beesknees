jQuery.noConflict();

jQuery(document).ready(function() {

  jQuery("#time").data("now", 3 * 60 * 1000)

  timer = new PeriodicalExecuter(function() {
    jQuery("#time").data("now", jQuery("#time").data("now") - 500);

    time = jQuery("#time").data("now");

    raw_minutes = time / 60 / 1000;
    minutes = raw_minutes.floor();
    seconds = ((raw_minutes - minutes) * 60).floor();

    jQuery("#time").text(minutes + ":" + seconds);
  }, 0.5);

  jQuery("#guess").focus();

  jQuery("form").submit(function() {
    jQuery.post(
      '/',
      {
        id:    jQuery('#game').val(),
        guess: jQuery('#guess').val()
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

        jQuery("." + list + "-list").prepend(
          "<li class='" + item + "'>" + res.guess + "</li>"
        );
        jQuery('.' + list + '-list li:first-child').slideDown();
        jQuery("#score").text(res.score);
        jQuery("#guess").val('').focus();
      },
      'json'
    );
  });
});
