class FacebookGraph
  include Hashie

  def initialize(facebook_token)
    @facebook_token = facebook_token
    @graph = Koala::Facebook::API.new(@facebook_token)
  end

  def get_avatar_url(uid)
    # pulled from old app
    # fb redirects the url given in the auth response, this is a workaround
    url = "http://graph.facebook.com/#{uid}/picture?type=large&width=9999&height=9999&redirect=false"
    begin
      JSON.parse(open(url).read)['data']['url']
    rescue
      url
    end
  end

  def build_account(user)
    @user = user
    @profile = @graph.get_object("me", fields: ['birthday', 'email', 'first_name', 'last_name', 'location'])
    birthday = format_birthday(@profile['birthday'])

    @user.email = @profile['email']
    @user.password = Devise.friendly_token[0,20]
    @user.first_name = @profile['first_name']
    @user.last_name = @profile['last_name']
    @user.birthday =  birthday
    @user.facebook_token = @facebook_token
    pull_education_data(@user)
    pull_location_data(@user, @profile)
  end

  def pull_education_data(user)
    @user = user
    @profile = @graph.get_object("me")
    return if @profile['education'].blank? 
    
    @profile['education'].each do |education|
      school_name = education['school']['name']
      school_name.gsub!(/[^A-Za-z0-9 ]*/, '') # Remove anything that's not alphunumeric or spaces
      school_name.gsub!(/\s+/, ' ') # Replace any consecutive spaces with a single space

      # First, try to find the school by Facebook ID
      if education['school']['id']
        @school = School.find_by(facebook_object_id: education['school']['id'])
      end

      # If that fails, try to find by name
      #
      # Sorry, this is the only way I can think to do this.  Here's what's going on:
      #   The problem is that a school might have different punctuations.  For
      #   example "University of California - Riverside" vs  "University of California: Riverside".
      #
      #   The inner regex removes any characters that are not A-Z, a-z, 0-9, and spaces.
      #   The outer regex takes any strings of multiple spaces and replaces them with a single space
      #
      #   So, both of the examples above would just turn into "University of California Riverside"
      #   We also pass the school_name in as a parameter, hence the ? at the end
      #
      #   Assuming we find a match, we return it.   
      #
      #   Also note that both the Ruby regex and the SQL regex do the same thing. I could do the
      #   parameter conversion in SQL as well, but seems simpler to do it in Ruby first and pass
      #   the simplified school_name as a parameter
      unless @school
        @school ||= School.find_by("regexp_replace(regexp_replace(name, '[^A-Za-z0-9 ]*', '', 'g'), '\s+', ' ', 'g') = ?", school_name)
      end

      if @school.present? && @school.facebook_object_id.blank?
        # Try to get additional info about the school and save it
        facebook_school = @graph.get_object(education['school']['id'])
        @school.facebook_object_id   = education['school']['id'] if education['school']['id']
        @school.facebook_type        = education['type'] if education['type']
        @school.facebook_description = facebook_school['description'] if facebook_school['description']
        @school.save
       
      # Didn't find a match? Create it.
      elsif @school.blank? 
        facebook_school = @graph.get_object(education['school']['id'])
        @school = School.create(name: education['school']['name'],
                                facebook_object_id: education['school']['id'],
                                facebook_type: education['type'],
                                facebook_description: education['school']['description'])
      end
      @user.schools << @school unless @user.already_associated_with?(@school)
    end
  end

  def pull_location_data(user, profile)
    return if @profile['location'].blank?

    if @profile['location']['id']
      location = @graph.get_object(@profile['location']['id'])
      if location
        @user.latitude = location['location']['latitude']
        @user.longitude = location['location']['longitude']
        @user.city_description = location['name']
      end
    end

  end

  def pull_facebook_friends
    @graph.get_connections("me", "friends?fields=id,name,picture.type(square)")
  end

  def pull_school_hashie(object_id)
    data = Mash.new(@graph.get_object(object_id))
    data
  end

  def pull_invitable_friends
    @graph.get_connections("me", "invitable_friends?fields=name,id,picture.type(square)")
  end

  def put_connections(*args)
    @graph.put_connections(*args)
  end

  private 

    # Facebook gives us a format which is different than what raise expects
    def format_birthday(date)
      return nil if date.nil?
      Date.strptime(date, '%m/%d/%Y')
    end
end
