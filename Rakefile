task :default => :gem

task :gem do
  `gem build ruboto-core.gemspec`
end

task :release do
  `gem push ruboto-core-0.0.1.gem`
end
