require 'action_view/helpers'

module BattlesHelper

  def battle_item_preview(item, size='medium')

    case item
    when Video
      if size == 'medium'
        <<-EOF.strip_heredoc
          #{link_to(image_tag(item.send("thumbnail_#{size}")), '#', 'data-reveal-id' => "videoModal-#{item.id}", 'data-reveal-ajax' => video_stuff_path(item))}
          <div id="videoModal-#{item.id}" class="reveal-modal large" data-reveal="true">
          </div>
        EOF
      else
        image_tag(item.send("thumbnail_#{size}"))
      end
    when Photo
      if size == 'medium'
        <<-EOF.strip_heredoc
          #{link_to( image_tag(item.file.url("#{size}_wide")), '#', 'data-reveal-id' => "photoModal-#{item.id}", 'data-reveal-ajax' => photo_stuff_path(item)) }
          <div id="photoModal-#{item.id}" class="reveal-modal large" data-reveal=true>
          </div>
        EOF
      else
        image_tag(item.file.url(size))
      end
    when Document
      if size == 'medium'
        <<-EOF.strip_heredoc
          #{link_to( image_tag(item.document_preview.url("#{size}_wide")), '#', 'data-reveal-id' => "photoModal-#{item.id}", 'data-reveal-ajax' => document_stuff_path(item)) }
          <div id="photoModal-#{item.id}" class="reveal-modal large" data-reveal=true>
          </div>
        EOF
      else
        link_to(image_tag(item.document_preview.url(size)), item)
      end
    when School
      image_tag(item.avatar.url(size))
    when Group
      image_tag(item.avatar.url(size))
    else
      if size == 'medium'
        image_tag("question-mark-box-#{size}-wide.png")
      else
        image_tag("question-mark-box-#{size}.png")
      end
    end
  end

  def battle_logo(kind)
    case kind
    when 'this_vs_that'
      image_tag('this_vs_that_logo.png')
    when 'me_vs_you'
      image_tag('me_vs_you_logo.png')
    when 'school_vs_school'
      image_tag('school_vs_school_logo.png')
    when 'group_vs_group'
      image_tag('group_vs_group_logo.png')
    end
  end

  def battle_time_left(battle)
    return if battle.ends_at.blank?
    if battle.ends_at.in_time_zone < Time.current
      "Ended at #{l battle.ends_at, format: :long}"
    else
      "Voting closes in  #{distance_of_time_in_words Time.current, battle.ends_at.in_time_zone}"
    end
  end

  def winner_panel(battle, item)
    return if battle.winner.nil?
    if battle.winner == item
      "<div class='winner'>Wins!</div>".html_safe
    end
  end

  def win_or_lose_id(battle, item)
    return unless battle.closed?
    if item == battle.first_item || item == battle.challenger # left side
      if battle.winner == item
        'challenger-winner-panel'
      elsif battle.winner == 'draw'
        'draw-panel'
      elsif battle.loser == item
        'loser-panel'
      end
    else
      if battle.winner == item
        'opponent-winner-panel'
      elsif battle.winner == 'draw'
        'draw-panel'
      elsif battle.loser == item
        'loser-panel'
      end
    end
  end

  def draw_panel(battle)
    return if battle.winner.nil?
    if battle.winner == 'draw'
      "<div class='draw'>Draw</div>".html_safe
    end
  end

  def status_header(battle)
    if battle.aasm_state == 'closed'
      '<h5> Battle Complete </h5>'.html_safe
    elsif battle.aasm_state == 'challenge_pending' && battle.opposing_user.present?
      "<h5><i class='fa fa-clock-o'></i> Challenge Pending </h5>".html_safe + 
      "Waiting for #{battle.opposing_user.full_name} to select an item and accept the challenge.".html_safe
    elsif battle.aasm_state == 'challenge_pending'
      "<h5><i class='fa fa-clock-o'></i> Challenge Pending </h5>".html_safe + 
      "Waiting for a member of #{battle.opponent.name} to accept the challenge and select an item.".html_safe
    elsif battle.aasm_state == 'open_for_voting'
      "<h5>Voting In Progress </h5>".html_safe + 
      "Voting closes in  #{distance_of_time_in_words Time.current, battle.ends_at}"
    elsif battle.aasm_state == 'pregame'
      ("<p>Pre-battle, just #{distance_of_time_in_words battle.game_time.in_time_zone, Time.current} remain to show your school spirit and buy battle passes.</p>" + 
            "Battle Time: #{l battle.game_time, format: :long}").html_safe
    elsif battle.aasm_state == 'gametime'
      "<h5>Battle Time </h5>".html_safe
    elsif battle.aasm_state == 'needs_scores'
      "<h5><i class='fa fa-clock-o'></i> Waiting for scores to be entered by #{link_to(battle.owner.full_name, battle.owner)}. </h5>".html_safe
    end
  end

  def gender_icon(gender)
    case gender
    when 'Mens'
      'mens_sport.png'
    when 'Womens'
      'womens_sport.png'
    else
      'co_ed_sport.png'
    end
  end

  def challenger_spirit_label(battle)
    if battle.challenger_battle_pass_total.to_f == battle.opponent_battle_pass_total.to_f
      "<div class='draw'>Equal Spirit</div>".html_safe
    elsif battle.challenger_battle_pass_total.to_f > battle.opponent_battle_pass_total.to_f
      "<div class='th more-spirit-panel-#{battle.id}'></i>#{image_tag( 'spirit-finger-green.png') }<p class='text-center'>More <br />Spirit</p></div>".html_safe
    end
  end

  def opponent_spirit_label(battle)
    if battle.opponent_battle_pass_total.to_f == battle.challenger_battle_pass_total.to_f
      "<div class='draw'>Equal Spirit</div>".html_safe
    elsif battle.opponent_battle_pass_total.to_f > battle.challenger_battle_pass_total.to_f
      "<div class='th more-spirit-panel-#{battle.id}'></i>#{image_tag( 'spirit-finger-blue.png') }<p class='text-center'>More <br />Spirit</p></div>".html_safe
    end
  end

end