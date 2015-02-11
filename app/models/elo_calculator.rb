class EloCalculator
  EloK = 32
  StartingRating = 1000
  
  def initialize(defeated_players, survived_players)
    @defeated_players = defeated_players
    @survived_players = survived_players
  end
  
  def calculate!
    defeated_r = avg_rank(@defeated_players)
    survived_r = avg_rank(@survived_players)
    
    defeated_q = q(defeated_r)
    survived_q = q(survived_r)
    
    defeated_e = expected(defeated_q, survived_q)
    survived_e = expected(survived_q, defeated_q)
    
    defeated_change = (change(defeated_e, 0.0) / @defeated_players.size).to_i
    survived_change = (change(survived_e, 1.0) / @survived_players.size).to_i
    
    @defeated_players.each do |p|
      p.rating = (p.try(:rating) || StartingRating) + defeated_change
      
      if (@survived_players.size > 0)
        p.games_lost = (p.games_lost || 0) + 1
      else
        p.games_drawn = (p.games_drawn || 0) + 1
      end
      
      p.save
    end
    
    @survived_players.each do |p|
      p.rating = (p.try(:rating) || StartingRating) + survived_change
      p.games_won = (p.games_won || 0) + 1 if @survived_players.size == 1
      p.save
    end
    
    return defeated_change, survived_change
  end
  
  
  
  protected
  
  def avg_rank(players)
    players.map { |p| p.try(:rating) || StartingRating }.sum.to_f / players.size
  end
  
  def q(rank)
    10.0 ** (rank.to_f / 400)
  end
  
  def expected(my_q, opp_q)
    my_q / (my_q + opp_q)
  end
  
  def change(expected, score)
    EloK * (score - expected)
  end
end
