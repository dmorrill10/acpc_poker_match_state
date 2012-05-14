
guard 'rspec', :version => 2 do
  players_at_the_table = 'players_at_the_table'
  watch("spec/#{players_at_the_table}_spec.rb")
  watch("lib/acpc_poker_match_state/#{players_at_the_table}.rb") { "spec/#{players_at_the_table}_spec.rb" }
  
  match_state_transition = 'match_state_transition'
  watch("spec/#{match_state_transition}_spec.rb")
  watch("lib/acpc_poker_match_state/#{match_state_transition}.rb") { "spec/#{match_state_transition}_spec.rb" }
end
