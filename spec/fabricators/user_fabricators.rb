Fabricator(:user) do
  username { Fabricate.sequence(:username) { |i| "player#{i}" } }
  email { Fabricate.sequence(:email) { |i| "player#{i}@example.com" } }
  password 'password'
  password_confirmation 'password'
  account_type 'subscriber'
  tid { (0...32).map{65.+(rand(25)).chr}.join }
end
