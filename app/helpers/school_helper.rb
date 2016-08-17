module SchoolHelper
  def join_school_button(school)
    return '' unless current_user

    fellowships = current_user.fellowships.where(school: school).where("status IS NULL OR status != 'pending'")

    if fellowships.count > 0
      roles_description = truncate(fellowships.map(&:role_with_year).map(&:capitalize).join(", "), length: 25)
      button = link_to fa_icon("check-circle lg", text: roles_description), '#', data: {dropdown: "role_types_menu_#{school.id}"}, class: 'button tiny button-pseudo-inactive dropdown radius'
    else
      button = link_to fa_icon("plus-circle lg", text: 'Join School'), '#', 'data-dropdown' => "role_types_menu_#{school.id}", class: "button tiny button-default dropdown radius"
    end
    
    ul = content_tag :ul, class: "f-dropdown", id: "role_types_menu_#{school.id}", "data-dropdown-content" => "true" do
      safe_join generate_list_elements(school, fellowships)
    end

    safe_join [button, ul]
  end
  
  private
  def generate_list_elements(school, fellowships)
    roles = fellowships.map(&:role)

    list_elements = []
    if fellowship = fellowships.find { |f| f.role == 'student' }
      list_elements << edit_student_graduation_li(school, fellowship)
      list_elements << leave_as_student_li(school, fellowship)
    else
      list_elements << join_as_student_li(school)
    end

    if fellowship = fellowships.find { |f| f.role == 'alumni' }
      list_elements << edit_alumni_graduation_li(school, fellowship)
      list_elements << leave_as_alumni_li(school, fellowship)
    elsif roles.include?('student')
      fellowship = fellowships.find { |f| f.role == 'student' }
      list_elements << become_an_alumni_li(fellowship)
    else
      list_elements << join_as_alumni_li(school)
    end

    if roles.include?('parent')
      list_elements << add_another_child_li(school)
    else
      list_elements << join_as_parent_li(school)
    end

    if fellowship = fellowships.find { |f| f.role == 'faculty' }
      list_elements << leave_as_faculty_li(school, fellowship)
    else
      list_elements << join_as_faculty_li(school)
    end

    if fellowship = fellowships.find { |f| f.role == 'monitor' && f.status == 'approved' }
      list_elements << leave_as_monitor_li(school, fellowship)
    end

    list_elements
  end

  def join_as_student_li(school)
    content_tag :li do
      link_to 'Join As Student', new_student_school_fellowships_path(school)
    end
  end

  def leave_as_student_li(school, fellowship)
    content_tag :li do
      link_to 'No longer student', school_fellowship_path(school, fellowship), method: :delete
    end
  end

  def edit_student_graduation_li(school, fellowship)
    content_tag :li do
      link_to 'Edit Student Graduation Date', edit_student_school_fellowship_path(school, fellowship)
    end
  end

  def join_as_alumni_li(school)
    content_tag :li do
      link_to 'Join As Alumni', new_alumni_school_fellowships_path(school)
    end
  end

  def edit_alumni_graduation_li(school, fellowship)
    content_tag :li do
      link_to 'Edit Alumni Graduation Date', edit_alumni_school_fellowship_path(school, fellowship)
    end
  end

  def become_an_alumni_li(fellowship)
    content_tag :li do
      link_to 'Become an alumni', become_alumni_school_fellowship_path(fellowship.school, fellowship)
    end
  end

  def leave_as_alumni_li(school, fellowship)
    content_tag :li do
      link_to 'No longer alumni', school_fellowship_path(school, fellowship), method: :delete
    end
  end

  def join_as_parent_li(school)
    content_tag :li do
      link_to 'Join As Parent', new_parent_school_fellowships_path(school)
    end
  end

  def add_another_child_li(school)
    content_tag :li do
      link_to 'Add another child', new_parent_school_fellowships_path(school)
    end
  end

  def join_as_faculty_li(school)
    content_tag :li do
      link_to 'Join As Faculty', new_faculty_school_fellowships_path(school)
    end
  end

  def leave_as_faculty_li(school, fellowship)
    content_tag :li do
      link_to 'No longer faculty', school_fellowship_path(school, fellowship), method: :delete
    end
  end

  def leave_as_monitor_li(school, fellowship)
    content_tag :li do
      link_to 'Resign as monitor', step_down_as_monitor_school_path(school), method: :post, data: {confirm: "Are you sure you want to resign as a monitor of #{school.full_name}?"}
    end
  end
end
