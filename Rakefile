#!/usr/bin/env rake

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)

task :ci do
  Rake::Task["standard"].invoke
  Rake::Task["spec"].invoke
end

task default: :ci
