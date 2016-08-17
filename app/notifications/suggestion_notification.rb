class SuggestionNotification < ApplicationNotification
  attr_accessor :suggestion, :suggester

  def body
    if suggestion.kind == 'logo'
      <<-EOF.strip_heredoc
        #{link_to(suggester.full_name, user_url(suggester))} has suggested a new logo for #{suggestion.suggestible.name}.
        #{link_to('Click Here', suggestions_url)} to approve or decline the new logo.
      EOF
    elsif suggestion.kind == 'about'
      <<-EOF.strip_heredoc
        #{link_to(suggester.full_name, user_url(suggester))} has suggested a new about us page for #{suggestion.suggestible.name}.
        #{link_to('Click Here', suggestions_url)} to approve or decline the new logo.
      EOF
    end
  end
end
