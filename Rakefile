task :default => :gem

task :gem do
  `gem build ruboto-core.gemspec`
end

task :release do
  sh "gem push #{Dir['ruboto-core-*.gem'][-1]}"
end

task :test do
  FileUtils.rm_rf Dir['tmp/RubotoTestApp_template*']
  Dir['test/*_test.rb'].each do |f|
    require f.chomp('.rb')
  end
end
