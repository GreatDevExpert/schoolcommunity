var FRAME_HELPER = {
  break_from_frame: function() {
    if (top.location != location) {
      top.location.href = document.location.href;
    }
  },
  embed_in_facebook_frame: function(app_id) {
    if (window == top.window) {
      window.location = "https://apps.facebook.com/" + app_id + "/facebook_payments/new"
    }
  }
};

$(document).ready(function() {
  /* Facebook payments require us to be embedded within a Facebook Canvas.
   * Otherwise the frame embedding is annoying, so break out of it. */
  if($('.require-facebook-frame').length > 0) {
    var app_id = $('.require-facebook-frame').first().attr('data-app-id');
    FRAME_HELPER.embed_in_facebook_frame(app_id);
  }
  else if($('.allow-facebook-frame').length > 0) {
    // noop
  }
  else {
    //FRAME_HELPER.break_from_frame();
  }

  /* Payment only works when embeeded within a Facebook Frame */
  $('.require-facebook-frame .facebook-pay-form').submit(function() {
    var form       = $(this);
    var id         = form.find('[name="id"]');
    var quantity   = form.find('[name="quantity"]').val();
    var request_id = form.find('[name="request_id"]').val();

    var internet_accessible_url = $('body').attr('data-internet-accessible-url');
    var product_url = internet_accessible_url + '/opengraph/facebook_scrilla';
    FB.ui({
      method     : 'pay',
      action     : 'purchaseitem',
      product    : product_url,
      quantity   : quantity,
      request_id : request_id
    },
    function(data) {
      if(data.error_message) {
        alert(data.error_message);
      }
      else {
        form.unbind('submit');
        form.submit();
      }
    });

    return (false);
  });

  /* DEBUGGING CODE */
  $('.reload').click(function() {
    window.location.reload();
  });
});
