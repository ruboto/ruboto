task :default => :gem

task :gem do
  `gem build ruboto-core.gemspec`
end

task :release do
  `gem push #{Dir['ruboto-core-*.gem'][-1]}`
end

task :test do
  Dir['test/*_test.rb'].each do |f|
    load f
  end
end
