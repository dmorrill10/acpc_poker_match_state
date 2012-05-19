require 'bundler/gem_tasks'
require 'rake'
require 'rspec/core/rake_task'

require File.expand_path('../lib/acpc_poker_match_state/version', __FILE__)
require File.expand_path('../tasks', __FILE__)

include Tasks

RSpec::Core::RakeTask.new(:spec) do |t|
   ruby_opts = "-w"
end

task :build => :spec do
   system "gem build acpc_poker_match_state.gemspec"
end

task :tag => :build do
   tag_gem_version AcpcPokerMatchState::VERSION
end
