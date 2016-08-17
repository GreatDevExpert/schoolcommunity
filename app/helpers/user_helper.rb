module UserHelper
  def friend_request_button(friend, options = {})
    button_classes = %w(button radius tiny)
    button_classes << options[:class] if options[:class]

    if current_user.friend?(friend)
      link_to fa_icon("check-circle lg", text: "Schoolies"), '#', class: 'button tiny button-inactive radius'
    elsif current_user.pending_friendship_request?(friend)
      link_to fa_icon("clock-o lg", text: "Request Pending"), '#', class: 'button tiny button-inactive radius'
    elsif policy(friend).send_friend_request?
      button_classes << %w(button button-default friend-request-button)
      link_to fa_icon("plus", text: "Become Schoolies"),
        user_friendship_requests_path(friend), method: :post,
        class: button_classes, remote: true
    else
      ''
    end
  end

  def information_for_connection_type(user, connection_type)
    return "" unless user && current_user

    case connection_type
    when "school"
      shared_schools_for(user)
    when "group"
      shared_group_for(user)
    when "mutual_friend"
      shared_friend_for(user)
    else
      school = school_for(user)
      if school.present?
        school
      else
        content_tag :div, user.city_description
      end
    end
  end

  def shared_group_for(user)
    return "" unless user && current_user
    
    # Find common groups
    common_groups = (current_user.groups & user.groups)
    if common_groups.present?
      "Member of the group '#{common_groups.first.full_name}'"
    else
      ""
    end
  end

  def shared_schools_for(user)
    # Find common schools
    common_schools = (current_user.schools & user.schools)
    if common_schools.present?
      school = common_schools.first
      safe_join [
        content_tag(:div, school.full_name),
        content_tag(:div, graduation_year_for_user_and_school(user, school))
      ]
    else
      ""
    end
  end

  def graduation_year_for_user_and_school(user, school)
    fellowships = user.fellowships.where(school: school).where(role: ['student', 'alumni'])
    if fellowships.present?
      content_tag :div, fellowships.first.long_graduation_year
    else
      ""
    end
  end

  def school_for(user)
    if user.fellowships.present?
      fellowship = user.fellowships.first

      if fellowship.role == 'student' || fellowship.role == 'alumni'
        safe_join [
          content_tag(:div, fellowship.school.full_name),
          content_tag(:div, fellowship.long_graduation_year)
        ]
      else
          content_tag(:div, fellowship.school.full_name)
      end
    else
      ""
    end
  end

  def shared_friend_for(user)
    return "" unless current_user && user

    shared_friends = current_user.friends & user.friends
    if shared_friends.present?
      content_tag :div, "Schoolies with #{shared_friends.first.full_name}"
    else
      ""
    end
  end
end
