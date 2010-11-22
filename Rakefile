task :default => :gem

task :gem do
  `gem build ruboto-core.gemspec`
end

task :release do
  `gem push #{Dir['ruboto-core-*.gem'][-1]}`
end

