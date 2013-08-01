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

  s.add_dependency 'acpc_poker_types', '~> 6.1'
  s.add_dependency 'contextual_exceptions', '~> 0.0'

  s.rubyforge_project = "acpc_poker_match_state"

  s.files         = Dir.glob("lib/**/*") + Dir.glob("ext/**/*") + %w(Rakefile acpc_poker_match_state.gemspec README.md)
  s.test_files    = Dir.glob "spec/**/*"
  s.require_paths = ["lib"]

  s.add_development_dependency 'minitest', '~> 5.0.6'
  s.add_development_dependency 'acpc_dealer', '~> 2.0'
  s.add_development_dependency 'awesome_print', '~> 1.0'
  s.add_development_dependency 'simplecov', '~> 0.7'
end
