class SuggestionDeclinedNotification < ApplicationNotification
  attr_accessor :suggestion, :suggester

  def body
    if suggestion.kind == 'logo'
      <<-EOF.strip_heredoc
        Your new logo suggestion for #{suggestion.suggestible.name} has been declined.
      EOF
    elsif suggestion.kind == 'about'
      <<-EOF.strip_heredoc
        Your new suggestion for the about us secton of #{suggestion.suggestible.name} has been declined.
      EOF
    end
  end
end
