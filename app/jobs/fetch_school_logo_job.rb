require 'mechanize'
class FetchSchoolLogoJob < ActiveJob::Base
  queue_as :spider

  def perform(school)
    image_url = query_google(school)
    if image_url
      school.remote_avatar_url = image_url
      school.logo_processed = true
      school.save!
    end
  end

  private
  def query_google(school)
    agent = Mechanize.new do |agent|
      agent.user_agent_alias = 'Mac Safari'
    end

    query = "#{school.name}, #{school.city}"
    page = agent.get('https://www.google.com/imghp?hl=en&tab=ii')
    google_form = page.form('f')
    google_form.q = query
    page = agent.submit(google_form, google_form.buttons.first)

    image_url = page.search('.images_table img').first.attributes["src"].value
  end
end
