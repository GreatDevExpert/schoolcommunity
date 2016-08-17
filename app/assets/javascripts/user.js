$(document).ready(function() {
  $('.friend-request-button').on("click", function() {
    $(this).text("Sending request");
    $(this).prepend("<i class='fa fa-spinner fa-spin'></i> ");
  }).on("ajax:success", function() {
    $(this).text('Request Pending');
    $(this).removeClass('button-default friend-request-button');
    $(this).prepend("<i class='fa fa-check'></i> ");
    $(this).addClass('fa-check button-inactive');
  }).on("ajax:error", function(e, xhr, status, error) {
    alert(error);
  });

  $('.friend-request-approval-button').on("click", function() {
    $(this).text('Approving...');
    $(this).prepend("<i class='fa fa-spinner fa-spin'></i> ");
    
    // Remove the "Deny" button, if present
    $(this).parents('ul').find('.friend-request-deny-button').parent('li').remove();
  }).on("ajax:success", function() {
    var button = $(this);
    

    // Update button text
    button.text('Schoolies');
    button.removeClass('friend-request-approval-button');
    button.prepend("<i class='fa fa-check'></i> ");
    button.addClass('button-inactive');

    // Wait a couple of seconds, then remove the user profile entirely
    setTimeout(function() {
      button.parents('.user-preview-box').parent('li').fadeOut();
    }, 2 * 1000);
  }).on("ajax:error", function(e, xhr, status, error) {
    alert(error);
  });
});
