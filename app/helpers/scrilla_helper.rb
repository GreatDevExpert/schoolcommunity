module ScrillaHelper
  def formatted_scrilla_balance(amount, html='true')
    if html == 'true'
      ScrillaBalance.format_amount_html(amount)
    else
      ScrillaBalance.format_amount(amount)
    end
  end

  def formatted_scrilla_transfer_description(transfer)
    return '' unless transfer

    sender_name    = transfer.sender ? transfer.sender.full_name : 'MySchool'
    recipient_name = transfer.recipient ? transfer.recipient.full_name : 'MySchool'
    amount         = ScrillaBalance.format_amount_html(transfer.amount)

    case transfer.transfer_type
    when 'initial_deposit'
      safe_join(["Thanks for signing up! #{sender_name} deposited ", amount, " into your account to get started"])
    when 'transfer'
      safe_join(["#{sender_name} transfered ", amount, " to #{recipient_name}"])
    when 'facebook_purchase'
      safe_join(["#{recipient_name} purchased ", amount, " from Facebook"])
    when 'battle_purchase'
      safe_join(["#{sender_name} purchased a battle for ", amount])
    when 'battle_pass'
      safe_join(["#{sender_name} purchased a battle pass for ", amount])
    when 'battle_pass_upgrade'
      safe_join(["#{sender_name} purchased a battle pass upgrade for ", amount])
    when 'battle_payout_winner'
      safe_join(["#{sender_name} won scrilla in a school vs school battle, totaling ", amount])
    when 'battle_payout_draw'
      safe_join(["#{sender_name} received your scrilla back because the school vs school battle was a draw ", amount])
    when 'member_referral'
      safe_join(["Received ", amount, " for referring a member. Thanks for spreading the word!"])
    end
  end
end
