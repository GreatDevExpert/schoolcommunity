var invite_controller = {
  MAX_SELECTED: 50,
  INVITATION_TITLE: 'Invite friends to MySchool',
  INVITATION_MESSAGE: 'Invite your friends to join MySchool',
  SUCCESS_MESSAGE: 'Your invitations have been sent.  Thanks for spreading the word!',

  selected_friends: [],

  init: function() {
    var self = this;
    self.update_button_state();
    self.setup_click_handler();
    self.setup_button_handler();
    self.setup_search_field();
  },
  setup_click_handler: function() {
    var self = this;
    $('#friends-container').on('click', '.invite-grid .friend', function() {
      var facebook_id = $(this).attr('data-facebook-id');
      self.toggle_selected(facebook_id);
      self.update_selected_state();
      self.update_button_state();
    });
  },
  setup_button_handler: function() {
    var self = this;
    $('#invitation-button').click(function() {
      FB.ui({
        method: 'apprequests',
        title   : self.INVITATION_TITLE,
        to      : self.selected_friends,
        message : self.INVITATION_MESSAGE
      }, function(response) {
        if(!response.error_code) {
          var facebook_request_id = response.request;
          $.post('/facebook_requests', {facebook_request_id: facebook_request_id});
          alert(self.SUCCESS_MESSAGE);
        }
      });
    });
  },
  setup_search_field: function() {
    var ul_container = $('#friends-container ul.invite-grid');
    var li_container = $('#friends-container .invite-grid li');
    var search_field = $('#invite-friends-search');

    $(li_container).each(function() {
      var data_name = $.trim($(this).find('.friend .name').text());
      $(this).attr('data-name', data_name);
    });

    var refresh_search_results = function() {
      var value = $.trim($(search_field).val());
      var regex = new RegExp(value, 'i');
      $(li_container).each(function() {
        var friend = $(this);
        var name = friend.attr('data-name');
        if(name.match(regex)) {
          friend.show();
        }
        else {
          friend.hide();
        }
      });
    };

    var reflow_search_results = function() {
      $(li_container).filter(':hidden').detach().appendTo(ul_container);
    };

    var search_timeout;
    var reorder_timeout;
    $(search_field).on('input propertychange paste', function() {
      if(search_timeout) {
        clearTimeout(search_timeout);
      }
      if(reorder_timeout) {
        clearTimeout(reorder_timeout);
      }
      search_timeout = setTimeout(refresh_search_results, 250);
      reorder_timeout = setTimeout(reflow_search_results, 1000);
    });
  },
  toggle_selected: function(facebook_id) {
    var self = this;
    if($.inArray(facebook_id, self.selected_friends) >= 0) {
      self.selected_friends.splice( $.inArray(facebook_id, self.selected_friends), 1);
    }
    else {
      if(self.selected_friends.length >= self.MAX_SELECTED) {
        alert('A maximum of ' + self.MAX_SELECTED + ' friends can be invited at a time.');
      }
      else {
        self.selected_friends.push(facebook_id);
      }
    }
  },
  update_selected_state: function() {
    var self = this;
    $('#friends-container .friend').each(function() {
      var facebook_id = $(this).attr('data-facebook-id');
      if($.inArray(facebook_id, self.selected_friends) >= 0) {
        $(this).addClass('selected');
      }
      else {
        $(this).removeClass('selected');
      }
    });
  },
  update_button_state: function() {
    var self = this;
    if(self.selected_friends.length > 0) {
      $('#invitation-button').removeClass('disabled');
    }
    else {
      $('#invitation-button').addClass('disabled');
    }
  }
};

$(document).ready(function() {
  invite_controller.init();
});
