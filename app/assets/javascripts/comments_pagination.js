$(document).ready(function() {
  $('.comments').each(function() {
    var comment_container = $(this);
    var comments = comment_container.find('.comment');
    var max_comments = comment_container.attr('data-max-comments');
    if(!max_comments) {
      max_comments = 5;
    }
    if(comments.length > max_comments) {
      comments.slice(max_comments).hide();
      var show_all_html = "<div class='text-center'><a href='#' class='show-all-comments-link'>Show all " + comments.length + " comments</a></div>";
    }
    comment_container.append(show_all_html);
  });
  $('.show-all-comments-link').bind('click', function() {
    $(this).parents('.comments').find('.comment').show();
    $(this).hide();
    return (false);
  });
});
