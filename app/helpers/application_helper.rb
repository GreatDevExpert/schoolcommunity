module ApplicationHelper
  include TweetButton

  DISPLAY_RETINA_IMAGES = false

  def display_base_errors resource
    return '' if (resource.errors.empty?) or (resource.errors[:base].empty?)
    messages = resource.errors[:base].map { |msg| content_tag(:p, msg) }.join
    html = <<-HTML
    <div data-alert class="alert-box alert">
      #{messages}
    </div>
    HTML
    html.html_safe
  end

  def retina_image(default:, retina:, width:, height:, alt: nil)
    if DISPLAY_RETINA_IMAGES
      default_url = asset_url(default)
      retina_url  = asset_url(retina)

      data_tag = tag(:img, data: {interchange: "[#{default_url}, (default)], [#{retina_url}, (retina)]"}, width: width, height: height)
      noscript_tag = content_tag(:noscript, image_tag(default))
      safe_join [data_tag, noscript_tag]
    else
      image_tag(default, size: "#{width}x#{height}", alt: alt)
    end
  end

  def render_unique_activities(activities)
    render_activities(activities.to_a.uniq{|a| a.uuid })
  end

  def indefinite_articlerize(params_word)
      %w(a e i o u).include?(params_word[0].downcase) ? "an #{params_word}" : "a #{params_word}"
  end
  
end
