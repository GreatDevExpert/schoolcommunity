// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require foundation
//= require facebook-javascript-sdk
//= require foundation-datetimepicker
//= require foundation-datepicker
//= require chosen-jquery
//= require_tree .


$(function() {
  $(document).foundation(); 

  $('.fdatepicker').fdatepicker({
    format: 'mm/dd/yyyy',
    onRender: function (date) {
      var nowTemp = new Date((new Date()).valueOf() - 1000*60*60*24);
      var now = new Date(nowTemp.getFullYear(), nowTemp.getMonth(), nowTemp.getDate(), 0, 0, 0, 0);
      return date.valueOf() < now.valueOf() ? 'disabled' : '';
    }
  });

  $('.datetimepicker').fdatetimepicker({
    autoclose: true,
    showMeridian: true,
  });

  $('.chosen-select').chosen({
    // allow_single_deselect: true
    no_results_text: 'No results matched'
    // width: '200px'
  });

  $('.visibility-helper').click(function() {
    var show_target = $(this).attr('data-show');
    var hide_target = $(this).attr('data-hide');

    $(show_target).show();
    $(hide_target).hide();

    return (false);
  });


  $('.search-icon').click(function() {
    var search_icon = $(this);
    var container = search_icon.parent().find('.toggle');
    var input = container.find("input[type='text']");

    search_icon.hide();
    container.toggle(300, function() {
      input.focus();
      input.click(function(event) {
        event.stopPropagation(); // Prevent clicking inside the search icon from hiding it
      });
    });

    $('body').on('click.search-icon', function() {
      container.toggle(300, function() {
        search_icon.show();
      });
      $('body').off('click.search-icon');
    });

    return false;
  });
});

setTimeout(function() {
    $('.alert-box.alert').fadeOut('fast');
}, 4000); // <-- time in milliseconds

setTimeout(function() {
    $('.alert-box.success').fadeOut('fast');
}, 4000); // <-- time in milliseconds

