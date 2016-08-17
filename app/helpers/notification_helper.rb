module NotificationHelper
  def inbox_with_badge
    if current_user
      if notification_count > 0
        link_to notifications_path(filter: 'recent'), id: 'notifications-controller' do
          content_tag(:div, class: 'icon-wrapper', id: 'notifications-icon') do
            content_tag(:i, class: 'fa fa-bell') do
              content_tag(:div, notification_count, class: 'badge')
            end
          end
        end
      else 
        link_to notifications_path(filter: 'recent'), id: 'notifications-controller' do
          content_tag(:div, class: 'icon-wrapper', id: 'notifications-icon') do
            content_tag(:i, "", class: 'fa fa-bell')
          end
        end
      end
    end
  end
end
