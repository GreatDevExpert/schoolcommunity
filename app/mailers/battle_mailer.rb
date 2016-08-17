class BattleMailer < ActionMailer::Base
  default from: '"Myschool" <no-reply@myschool411.com>'

  def new_challenge(battle)
    @battle = battle
    @owner = @battle.owner
    @opposing_user = @battle.opposing_user
    mail(to: @opposing_user.email, subject: "#{@owner.first_name} has challenged you to a battle: #{@battle.description}")
  end

  def challenge_accepted(battle)
    @battle = battle
    @owner = @battle.owner
    @opposing_user = @battle.opposing_user
    mail(to: @owner.email, subject: "#{@opposing_user.first_name} has accepted your challenged.")
  end

  def battle_is_closed_winner(battle, winner)
    @battle = battle
    @winner = winner
    mail(to: @winner.email, subject: "You Battle Has Finished")
  end

  def battle_is_closed_loser(battle, loser)
    @battle = battle
    @loser = loser
    mail(to: @loser.email, subject: "You Battle Has Finished")
  end

  def battle_is_closed_draw(battle, user)
    @battle = battle
    @user = user
    mail(to: @user.email, subject: "You Battle Has Finished")
  end

  def ask_for_scores(battle, user)
    @battle = battle
    @user = user
    mail(to: @user.email, subject: "You Battle Has Finished")
  end

end
