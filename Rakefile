require 'rspec/core/rake_task'

task :default => :test

desc 'Miny API spec'
task :test do
  RSpec::Core::RakeTask.new(:test) do |t|
    t.pattern = 'spec/*_spec.rb'
  end
end
