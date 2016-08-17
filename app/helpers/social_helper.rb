module SocialHelper
  def social_share_icons
    links = safe_join [share_on_facebook, share_on_twitter]
    content_tag(:div, links, class: 'social-icons')
  end

  private
  def share_on_twitter
    tweet_button(count: 'horizontal', via: 'MySchool411', text: "Check this out:")
  end

  def share_on_facebook
    content_tag(:div, '', class: 'fb-share-button', data: {layout: 'button_count', href: request.original_url})
  end

end
