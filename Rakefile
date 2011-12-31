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

# @todo create helper rake task. Not sure if I'm doing this properly.

task :tag => :build do
   tag_gem_version AcpcPokerMatchState::VERSION
end

desc 'Integrate this gem into a given app'
task :integrate, :rel_app_path do |t, args|
   #Rake::Task[:tag].invoke
   Rake::Task[:build].invoke
   gem_name = "acpc_poker_match_state-#{AcpcPokerMatchState::VERSION}.gem"
   integrate_into_app args[:rel_app_path], gem_name
end

#desc "release gem to gemserver"
#task :release => [:tag, :deploy] do
#  puts "congrats, the gem is now tagged, pushed, deployed and released! Rember to up the VERSION number"
#end

#task :deploy do
#  puts "Deploying to gemserver@mygemserver.mycompany.com"
#  system "scp my_private_gem-#{AcpcPokerType::VERSION}.gem gemserver@mygemserver.mycompany.com:gems/."
#  puts "installing on gemserver"
#  system "ssh gemserver@mygemserver.mycompany.com \"cd gems && gem install my_private_gem-#{AcpcPokerType::VERSION}.gem --ignore-dependencies\""
#end
