class SuggestionApprovedNotification < ApplicationNotification
  attr_accessor :suggestion, :suggester

  def body
    if suggestion.kind == 'logo'
      <<-EOF.strip_heredoc
        Your new logo suggestion for #{suggestion.suggestible.name} has been approved!
        #{link_to('Click Here', polymorphic_url(suggestion.suggestible))} to see the new logo.
      EOF
    elsif suggestion.kind == 'about'
      <<-EOF.strip_heredoc
        Your new suggestion for the about us secton of #{suggestion.suggestible.name} has been approved!
        #{link_to('Click Here', polymorphic_url([:about, suggestion.suggestible]))} to see the new about page.
      EOF
    end
  end
end
