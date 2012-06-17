$:.push File.expand_path("../lib", __FILE__)
require File.expand_path('../lib/acpc_poker_match_state/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = "acpc_poker_match_state"
  s.version     = AcpcPokerMatchState::VERSION
  s.authors     = ["Dustin Morrill"]
  s.email       = ["morrill@ualberta.ca"]
  s.homepage    = "https://github.com/dmorrill10/acpc_poker_match_state"
  s.summary     = %q{ACPC Poker Match State}
  s.description = %q{Match state data manager.}
  
  s.add_dependency 'acpc_poker_types'
  s.add_dependency 'dmorrill10-utils'

  s.rubyforge_project = "acpc_poker_match_state"

  s.files         = Dir.glob("lib/**/*") + Dir.glob("ext/**/*") + %w(Rakefile acpc_poker_match_state.gemspec tasks.rb README.md)
  s.test_files    = Dir.glob "spec/**/*"
  s.require_paths = ["lib"]

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'simplecov'
end
