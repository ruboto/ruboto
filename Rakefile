$:.unshift('lib') unless $:.include?('lib')
require 'rake/clean'
require 'rexml/document'
require 'ruboto/version'
require 'ruboto/description'
require 'ruboto/sdk_versions'
require 'uri'
require 'net/http'

PLATFORM_PROJECT = File.expand_path('tmp/RubotoCore', File.dirname(__FILE__))
PLATFORM_DEBUG_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk"
PLATFORM_DEBUG_APK_BAK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk.bak"
PLATFORM_RELEASE_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-release.apk"
PLATFORM_CURRENT_RELEASE_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-release.apk.current"
MANIFEST_FILE = "AndroidManifest.xml"
GEM_FILE = "ruboto-#{Ruboto::VERSION}.gem"
GEM_SPEC_FILE = 'ruboto.gemspec'
EXAMPLE_FILE = File.expand_path("examples/RubotoTestApp_#{Ruboto::VERSION}_tools_r#{Ruboto::SdkVersions::ANDROID_TOOLS_REVISION}.tgz", File.dirname(__FILE__))

CLEAN.include('ruboto-*.gem', 'tmp')

task :default => :gem

desc "Generate a gem"
task :gem => GEM_FILE

file GEM_FILE => GEM_SPEC_FILE do
  puts "Generating #{GEM_FILE}"
  `gem build #{GEM_SPEC_FILE}`
end

task :install => :gem do
  `gem query -i -n ^ruboto$ -v #{Ruboto::VERSION}`
  if $? != 0
    puts 'Installing gem'
    cmd = "gem install ruboto-#{Ruboto::VERSION}.gem"
    output = `#{cmd}`
    if $? == 0
      puts output
    else
      sh "sudo #{cmd}"
    end
  else
    puts "ruboto-#{Ruboto::VERSION} is already installed."
  end
end

task :uninstall do
  `gem query -i -n ^ruboto$ -v #{Ruboto::VERSION}`
  if $? == 0
    puts 'Uninstalling gem'
    cmd = "gem uninstall ruboto -v #{Ruboto::VERSION}"
    output = `#{cmd}`
    if $? == 0
      puts output
    else
      sh "sudo #{cmd}"
    end
  else
    puts "ruboto-#{Ruboto::VERSION} is not installed."
  end
end

task :reinstall => [:uninstall, :clean, :install]

desc "Generate an example app"
task :example => EXAMPLE_FILE

file EXAMPLE_FILE => :install do
  puts "Creating example app #{EXAMPLE_FILE}"
  app_name = 'RubotoTestApp'
  Dir.chdir File.dirname(EXAMPLE_FILE) do
    FileUtils.rm_rf app_name
    sh "ruboto gen app --package org.ruboto.test_app --name #{app_name} --path #{app_name}"
    sh "tar czf #{EXAMPLE_FILE} #{app_name}"
    FileUtils.rm_rf app_name
  end
end

desc 'Generate release docs for a given milestone'
task :release_docs do
  raise "\n    This task requires Ruby 1.9 or newer to parse JSON as YAML.\n\n" if RUBY_VERSION == '1.8.7'
  puts 'GitHub login:'
  begin
    require 'rubygems'
    require 'highline/import'
    user = ask('login   : ') { |q| q.echo = true }
    pass = ask('password: ') { |q| q.echo = '*' }
  rescue
    print 'user name: ' ; user = STDIN.gets.chomp
    print ' password: ' ; pass = STDIN.gets.chomp
  end
  require 'uri'
  require 'net/http'
  require 'net/https'
  require 'openssl'
  require 'yaml'
  host = 'api.github.com'
  base_uri = "https://#{host}/repos/ruboto/ruboto"
  https = Net::HTTP.new(host, 443)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE

  milestone_uri = URI("#{base_uri}/milestones")
  req = Net::HTTP::Get.new(milestone_uri.request_uri)
  req.basic_auth(user, pass)
  res = https.start { |http| http.request(req) }
  milestones = YAML.load(res.body).sort_by { |i| Date.parse(i['due_on']) }
  puts milestones.map{|m| "#{'%2d' % m['number']} #{m['title']}"}.join("\n")

  if defined? ask
    milestone = ask('milestone: ', Integer) { |q| q.echo = true }
  else
    print 'milestone: ' ; milestone = STDIN.gets.chomp
  end

  uri = URI("#{base_uri}/issues?milestone=#{milestone}&state=closed&per_page=1000")
  req = Net::HTTP::Get.new(uri.request_uri)
  req.basic_auth(user, pass)
  res = https.start { |http| http.request(req) }
  issues = YAML.load(res.body).sort_by { |i| i['number'] }
  milestone_name = issues[0] ? issues[0]['milestone']['title'] : "No issues for milestone #{milestone}"
  milestone_description = issues[0] ? issues[0]['milestone']['description'] : "No issues for milestone #{milestone}"
  categories = {'Features' => 'feature', 'Bugfixes' => 'bug', 'Internal' => 'internal', 'Support' => 'support', 'Documentation' => 'documentation', 'Pull requests' => nil, 'Other' => nil}
  grouped_issues = issues.group_by do |i|
    labels = i['labels'].map { |l| l['name']}
    cat = nil
    categories.each do |k,v|
      if labels.include? v
        cat = k
        break
      end
    end
    cat ||= i['pull_request'] && 'Pull requests'
    cat ||= 'Other'
    cat
  end
  puts
  puts "Subject: [ANN] Ruboto #{milestone_name} released!"
  puts
  puts "The Ruboto team is proud to announce the release of Ruboto #{milestone_name}."
  puts
  puts Ruboto::DESCRIPTION
  puts
  puts "New in version #{milestone_name}:\n"
  puts
  puts milestone_description
  puts
  (categories.keys & grouped_issues.keys).each do |cat|
    puts "#{cat}:\n\n"
    grouped_issues[cat].each { |i| puts %Q{* Issue ##{i['number']} #{i['title']}} }
    puts
  end
  puts "You can find a complete list of issues here:\n\n"
  puts "* https://github.com/ruboto/ruboto/issues?state=closed&milestone=#{milestone}\n\n"
  puts
  puts <<EOF
Installation:

To use Ruboto, you need to install a Java JDK, the Android SDK, Apache ANT, and a Ruby implementation.  Then do (possibly as root)

    gem install ruboto


To create a project do

    ruboto gen app --package <your.package.name>


You can find an introductory tutorial at https://github.com/ruboto/ruboto/wiki/Getting-started-with-Ruboto

If you have any problems or questions, come see us at http://ruboto.org/

Enjoy!


--
The Ruboto Team
http://ruboto.org/

EOF

end

desc 'Fetch download stats form rubygems.org'
task :stats do
  require 'time'
  require 'date'
  require 'rubygems'
  require 'uri'
  require 'net/http'
  require 'net/https'
  require 'openssl'
  require 'yaml'
  host = 'rubygems.org'
  base_uri = "https://#{host}/api/v1"
  https = Net::HTTP.new(host, 443)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE

  counts_per_month = Hash.new{|h, k| h[k] = Hash.new{|mh,mk| mh[mk] = 0 }}
  total = 0

  %w{ruboto-core ruboto}.each do |gem|
    versions_uri = URI("#{base_uri}/versions/#{gem}.yaml")
    req = Net::HTTP::Get.new(versions_uri.request_uri)
    res = https.start { |http| http.request(req) }
    versions = YAML.load(res.body).sort_by { |v| Gem::Version.new(v['number']) }
    puts "\n#{gem}:\n#{versions.map { |v| "#{Time.parse(v['built_at']).strftime('%Y-%m-%d')} #{'%10s' % v['number']} #{v['downloads_count']}" }.join("\n")}"

    versions.each do |v|
      downloads_uri = URI("#{base_uri}/versions/#{gem}-#{v['number']}/downloads/search.yaml?from=#{Time.parse(v['built_at']).strftime('%Y-%m-%d')}&to=#{Date.today}")
      req = Net::HTTP::Get.new(downloads_uri.request_uri)
      res = https.start { |http| http.request(req) }
      counts = YAML.load(res.body)
      counts.delete_if{|date_str,count| count == 0}
      counts.each do |date_str, count|
        date = Date.parse(date_str)
        counts_per_month[date.year][date.month] += count
        total += count
      end
      print '.' ; STDOUT.flush
    end
    puts
  end

  puts "\nDownloads statistics per month:"
  years = counts_per_month.keys
  puts "\n    #{years.map{|year| '%6s:' % year}.join(' ')}"
  (1..12).each do |month|
    print "#{'%2d' % month}:"
    years.each do |year|
      count = counts_per_month[year][month]
      print count > 0 ? '%8d' % count : ' ' * 8
    end
    puts
  end

  puts "\nTotal: #{total}\n\n"

  puts "\nRubyGems download statistics per month:"
  years = counts_per_month.keys
  puts '    ' + years.map{|year| '%-12s' % year}.join
  (0..20).each do |l|
    print (l % 10 == 0) ? '%4d' % ((20-l) * 100) : '    '
    years.each do |year|
      (1..12).each do |month|
        count = counts_per_month[year][month]
        if [year, month] == [Date.today.year, Date.today.month]
          count *= (Date.new(Date.today.year, Date.today.month, -1).day.to_f / Date.today.day).to_i
        end
        print count > ((20-l) * 100) ? '*' : ' '
      end
    end
    puts
  end
  puts '    ' + years.map{|year| '%-12s' % year}.join

  puts "\nTotal: #{total}\n\n"
end

desc "Push the gem to RubyGems"
task :release => [:clean, :gem] do
  output = `git status --porcelain`
  raise "Workspace not clean!\n#{output}" unless output.empty?
  sh "git tag #{Ruboto::VERSION}"
  sh "git push --tags"
  sh "gem push #{GEM_FILE}"

  examples_glob = "#{EXAMPLE_FILE.slice(/^.*?_\d+\.\d+\.\d+/)}*"
  sh "git rm #{examples_glob}" unless Dir[examples_glob].empty?
  Rake::Task[:example].invoke
  sh "git add #{EXAMPLE_FILE}"
  sh "git commit -m '* Added example app for Ruboto #{Ruboto::VERSION} tools r#{Ruboto::SdkVersions::ANDROID_TOOLS_REVISION}' \"#{examples_glob}\""
  sh "git push"
end

desc "Run the tests"
task :test do
  FileUtils.rm_rf Dir['tmp/RubotoTestApp_template*']
  Dir['./test/*_test.rb'].each do |f|
    require f.chomp('.rb')
  end
end

namespace :platform do
  desc 'Remove Ruboto Core platform project'
  task :clean do
    FileUtils.rm_rf PLATFORM_PROJECT
  end

  desc 'Generate the Ruboto Core platform project'
  task :project => PLATFORM_PROJECT

  file PLATFORM_PROJECT do
    sh "ruby -rubygems -I#{File.expand_path('lib', File.dirname(__FILE__))} bin/ruboto gen app --package org.ruboto.core --name RubotoCore --with-jruby --path #{PLATFORM_PROJECT} --min-sdk #{Ruboto::SdkVersions::MINIMUM_SUPPORTED_SDK} --target #{Ruboto::SdkVersions::DEFAULT_TARGET_SDK}"
    Dir.chdir(PLATFORM_PROJECT) do
      manifest = REXML::Document.new(File.read(MANIFEST_FILE))
      manifest.root.attributes['android:versionCode'] = '409'
      manifest.root.attributes['android:versionName'] = '0.4.9'
      manifest.root.attributes['android:installLocation'] = 'auto' # or 'preferExternal' ?
      File.open(MANIFEST_FILE, 'w') { |f| manifest.document.write(f, 4) }
      File.open('Gemfile.apk', 'w'){|f| f << "source :rubygems\n\ngem 'activerecord-jdbc-adapter'\n"}
      File.open('ant.properties', 'a'){|f| f << "key.store=${user.home}/ruboto_core.keystore\nkey.alias=Ruboto\n"}
    end
  end

  desc 'Generate a Ruboto Core platform debug apk'
  task :debug => PLATFORM_DEBUG_APK

  task PLATFORM_DEBUG_APK do
    Rake::Task[PLATFORM_PROJECT].invoke
    Dir.chdir(PLATFORM_PROJECT) do
      if File.exists?(PLATFORM_CURRENT_RELEASE_APK) && File.exists?(PLATFORM_DEBUG_APK) &&
          File.size(PLATFORM_CURRENT_RELEASE_APK) == File.size(PLATFORM_DEBUG_APK)
        if File.exists?(PLATFORM_DEBUG_APK_BAK)
          FileUtils.cp PLATFORM_DEBUG_APK_BAK, PLATFORM_DEBUG_APK
        else
          FileUtils.rm PLATFORM_DEBUG_APK
        end
      end
      sh 'rake debug'
    end
  end

  desc 'Generate a Ruboto Core platform release apk'
  task :release => PLATFORM_RELEASE_APK

  file PLATFORM_RELEASE_APK => PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake release'
    end
  end

  desc 'Download the current RubotoCore platform release apk'
  file PLATFORM_CURRENT_RELEASE_APK do
    puts 'Downloading the current RubotoCore platform release apk'
    url = 'http://cloud.github.com/downloads/ruboto/ruboto/RubotoCore-release.apk'
    begin
      File.open(PLATFORM_CURRENT_RELEASE_APK, 'w') { |f| f << Net::HTTP.get(URI.parse url) }
    rescue Exception, SystemExit
      FileUtils.rm(PLATFORM_CURRENT_RELEASE_APK) if File.exists?(PLATFORM_CURRENT_RELEASE_APK)
      raise
    end
  end

  desc 'Use the current RubotoCore platform release apk'
  task :current => [:debug, PLATFORM_CURRENT_RELEASE_APK] do
    Dir.chdir PLATFORM_PROJECT do
      if File.size(PLATFORM_CURRENT_RELEASE_APK) != File.size(PLATFORM_DEBUG_APK)
        FileUtils.cp PLATFORM_DEBUG_APK, PLATFORM_DEBUG_APK_BAK
        FileUtils.cp PLATFORM_CURRENT_RELEASE_APK, PLATFORM_DEBUG_APK
      end
    end
  end

  desc 'Install the Ruboto Core platform debug apk'
  task :install => PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake install'
    end
  end

  desc 'Uninstall the Ruboto Core platform debug apk'
  task :uninstall => PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake uninstall'
    end
  end
end
