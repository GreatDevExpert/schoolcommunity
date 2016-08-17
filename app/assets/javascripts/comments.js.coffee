# http://twocentstudios.com/blog/2012/11/15/simple-ajax-comments-with-rails/

jQuery ->

  # for creating a comment when a page has just one comment form
  $(".comment-form")
    .on "ajax:beforeSend", (evt, xhr, settings) ->
      $(this).find('input')
        .addClass('uneditable-input')
        .attr('disabled', 'disabled');
    .on "ajax:success", (evt, data, status, xhr) ->
      $(this).find('input')
        .removeClass('uneditable-input')
        .removeAttr('disabled', 'disabled')
        .val('');
      $(xhr.responseText).hide().insertAfter($(".latest-comment")).show(
        'slow', -> $(document).foundation('dropdown', 'reflow')
        )
        # need to make sure foundation's drop down button menu is on the left so we use reflow

  # for creating a comment when a page has more than one comment form
  object_name_and_ids = $(".parent-object") #grab ids of each form
  targets = []

  # build the array
  object_name_and_ids.each ->
    data = $(this).data('object-class-and-id')
    targets.push(data)
  
  # iterate over each array
  targets.map (object_name_and_id) ->
    $("#comment-form-#{object_name_and_id}")
      .on "ajax:beforeSend", (evt, xhr, settings) ->
        $(this).find('input')
          .addClass('uneditable-input')
          .attr('disabled', 'disabled');
      .on "ajax:success", (evt, data, status, xhr) ->
        $(this).find('input')
          .removeClass('uneditable-input')
          .removeAttr('disabled', 'disabled')
          .val('');
        $(xhr.responseText).hide().insertAfter($("#latest-comment-#{object_name_and_id}")).show(
          'slow', -> $(document).foundation('dropdown', 'reflow')
          )
          # need to make sure foundation's drop down button menu is on the left so we use reflow


