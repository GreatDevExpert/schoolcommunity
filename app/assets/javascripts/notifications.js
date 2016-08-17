$(document).ready(function() {
  $('#notifications-controller').click(function(event) {
    var icon = $(this);
    var dropdown_parent = $(this).parents('li');
    var dropdown = dropdown_parent.find('.notification-dropdown');
    // On first load, pull the notifications using AJAX
    if(dropdown.length == 0) {
      dropdown_parent.append('<div class="notification-dropdown"></div>');
      dropdown = dropdown_parent.find('.notification-dropdown');
      dropdown.hide();
      $.ajax('/notifications/recent', {
        type: 'GET',
        cache: false,
        dataType: 'json',
        success: function(data) {
          if(data && data.success == true && data.html) {
            $('.notification-dropdown').html(data.html);
            dropdown.show();

            $('html').click(function() {
              dropdown.hide();
            });
          }
        },
        error: function(xhr, status, error) {
          window.location.href = '/notifications?filter=recent';
        }
      });
    }
    // On subsequent loads, just show or hide the notifications panel
    else {
      if(dropdown.is(':visible')) {
        dropdown.hide();
      }
      else {
        dropdown.show();
      }
    }

    $('.has-dropdown.hover').removeClass('hover');
    return (false);
  });

  $(document.body).on( "click", '.update-read-status', function() {
    var notification = $(this).parents('.notification');
    var url = $(this).attr('href');
    $.ajax(url, {
      type: 'PUT',
      cache: false,
      dataType: 'json',
      success: function() {
        if(notification.hasClass('read')) {
          notification.removeClass('read').addClass('unread');
        }
        else {
          notification.removeClass('unread').addClass('read');
        }
      },
      error: function(xhr, status, error) {
        alert('An error occurred updating your message status.');
      }
    });
    return (false);
  });

  $(document.body).on( "click", '.mark-all-as-read', function() {
    var url = $(this).attr('href');
    $.ajax(url, {
      type: 'POST',
      cache: false,
      dataType: 'json',
      success: function() {
        $('.notification.unread').removeClass('unread').addClass('read');
        $('#notifications-controller .badge').hide();

        var read_all_cont = $('.notification-dropdown .mark-all-as-read').parents('.medium-6.columns');
        var view_all_link_cont = $('.notification-dropdown .view-all').parents('.medium-6.columns');

        read_all_cont.remove();
        view_all_link_cont.removeClass('.medium-6').addClass('medium-12');
      },
      error: function(xhr, status, error) {
        alert('An error occurred updating your message status.');
      }
    });
    return (false);
  });
})
