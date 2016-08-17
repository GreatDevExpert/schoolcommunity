class SharingOptionBuilder
  class PrivateSharingOption
    def name
      "Do not share"
    end

    def identifier
      "private"
    end
  end

  def initialize(user)
    @user = user
  end

  def post_options
    options
  end

  def photo_options
    options.push(PrivateSharingOption.new)
  end
  alias_method :video_options, :photo_options
  alias_method :document_options, :photo_options

  private
  def options
    @options ||= (fellowships + @user.groups.order('name'))
  end

  def fellowships
    @user.fellowships.where(role: ['student', 'alumni', 'faculty', 'parent']).joins(:school).order("schools.name")
  end
end
