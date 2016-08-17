$(document).ready(function() {
  $('.stuff-uploader form').each(function() {
    var form = $(this);
    var file_field = form.find(':file');
    file_field.change(function() {
      $('#image_cache_preview').empty();
      $('#document_cache_preview').empty();
      $('#video_cache_preview').empty();
      $('.existing-stuff').val("");
    });
  });

  $('.stuff-target').each(function() {
    var stuff_target = $(this);

    // When a link is clicked, load the image via AJAX and replace into DOM
    $(this).on('click', '.stuff-selector a', function() {
      var selector = $('.stuff-selector');
      var link = $(this);
      var url = link.attr('href');

      $.ajax(url, {
        type: 'GET',
        cache: false,
        success: function(data) {
          $(selector).html(data);
        },
        error: function() {
          alert('Unable to load data. Please refresh your page and try again');
        }
      });

      return (false);
    });

    // When a form is submitted, load the results via AJAX and replace into DOM
    $(this).on('submit', '.stuff-selector form.ajax', function(event) {
      var selector = $('.stuff-selector');
      var form = $(this);
      var url = form.attr('action');

      $.ajax(url, {
        type: 'GET',
        cache: false,
        data: form.serialize(),
        success: function(data) {
          selector.html(data);
        },
        error: function() {
          alert('Unable to load data. Please refresh your page and try again');
        }
      });

      event.preventDefault();

      return (false);
    });

    // Enable submit button when an item is selected
    $(this).on('change', '.stuff-selector input[type="radio"]', function() {
      $('.stuff-selector input[type="submit"]').removeAttr('disabled').removeClass('disabled');
    });

    // When photo is chosen, persist results to form
    $(this).on('submit', '#photo-selector-form', function(event) {
      var selected = $(this).find(':radio').filter(':checked');
      if(selected.length > 0) {
        var photo_id = selected.val();
        var preview_url = selected.attr('data-preview-url');
        var image_html = "<img src='" + preview_url + "'>";

        $('.stuff-uploader :file').val('');
        $('.existing-stuff').val(photo_id);
        $('#image_cache_preview').html(image_html);
        stuff_target.foundation('reveal', 'close');

      }
      else {
        alert("Please select a photo");
      }
      return (false);
    });

    // When video is chosen, persist results to form
    $(this).on('submit', '#video-selector-form', function(event) {
      var selected = $(this).find(':radio').filter(':checked');
      if(selected.length > 0) {
        var video_id = selected.val();
        var preview_url = selected.attr('data-preview-url');
        var image_html = "<img src='" + preview_url + "'>";

        $('.stuff-uploader :file').val('');
        $('.existing-stuff').val(video_id);
        $('#video_cache_preview').html(image_html);
        stuff_target.foundation('reveal', 'close');

      }
      else {
        alert("Please select a video");
      }
      return (false);
    });

    // When document is chosen, persist results to form
    $(this).on('submit', '#document-selector-form', function(event) {
      var selected = $(this).find(':radio').filter(':checked');
      if(selected.length > 0) {
        var document_id = selected.val();
        var preview_url = selected.attr('data-preview-url');
        var image_html = "<img src='" + preview_url + "'>";

        $('.stuff-uploader :file').val('');
        $('.existing-stuff').val(document_id);
        $('#document_cache_preview').html(image_html);
        stuff_target.foundation('reveal', 'close');

      }
      else {
        alert("Please select a document");
      }
      return (false);
    });


  });
});
