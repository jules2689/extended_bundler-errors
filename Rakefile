require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
end

task :default => :test

task :index_handlers do
  require 'time'
  File.open("index", "w") do |f|
    Dir.glob("lib/extended_bundler/handlers/*.yml") do |file|
      f.puts("#{file},#{File.mtime(file).utc.iso8601}")
    end
  end
end
