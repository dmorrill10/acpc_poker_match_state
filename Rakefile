#!/usr/bin/env rake
require 'bundler/gem_tasks'
require 'rake'
require 'rake/testtask'

require File.expand_path('../lib/acpc_poker_match_state/version', __FILE__)
require File.expand_path('../tasks', __FILE__)

include Tasks

Rake::TestTask.new do |t|
  t.libs << "lib" << 'spec/support'
  t.test_files = FileList['spec/**/*_spec.rb']
  t.verbose = true
  t.warning = true
end
