$(document).ready(function() {
  $('label .selectable-battle-thumb img').click(function(){
    var url = $(this).attr('src');
    var html = '<img src="'+url+'">';
    $(".change-item-preview").html(html);
  });

  $('.fellowship_type_select').click(function(){
    var school_id = $(this).attr('data-school-id');
    var fellowship_role = $(this).attr('data-fellowship-role');
    $('#battles_find_and_join_school_school_id').val(school_id);
    $('#battles_find_and_join_school_fellowship_role').val(fellowship_role);
    return false;
  });

  $('.membership_type_select').click(function(){
    var group_id = $(this).attr('data-group-id');
    var membership_role = $(this).attr('data-membership-role');
    $('#battles_find_and_join_group_group_id').val(group_id);
    $('#battles_find_and_join_group_membership_role').val(membership_role);
    return false;
  });
});
