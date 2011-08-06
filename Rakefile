task :default => :gem

desc "Generate a gem"
task :gem do
  `gem build ruboto-core.gemspec`
end

desc "Push the gem to RubyGems"
task :release do
  sh "gem push #{Dir['ruboto-core-*.gem'][-1]}"
end

desc "Run the tests"
task :test do
  FileUtils.rm_rf Dir['tmp/RubotoTestApp_template*']
  Dir['test/*_test.rb'].each do |f|
    require f.chomp('.rb')
  end
end
