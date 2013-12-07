require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task :default => [:spec, :rubocop]

desc 'Miny API spec'
RSpec::Core::RakeTask.new(:spec)

desc 'Validate against rubocop'
Rubocop::RakeTask.new(:rubocop) do |task|
  task.patterns = ['lib/*.rb', 'spec/']
  task.fail_on_error = true
end
