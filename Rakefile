$:.unshift('lib') unless $:.include?('lib')
require 'date'
require 'rake/clean'
require 'rexml/document'
require 'ruboto/version'
require 'ruboto/description'
require 'ruboto/sdk_versions'
require 'uri'
require 'net/https'

PROJECT_DIR = File.expand_path(File.dirname(__FILE__))
PLATFORM_PROJECT = File.expand_path('tmp/RubotoCore', File.dirname(__FILE__))
PLATFORM_DEBUG_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk"
PLATFORM_DEBUG_APK_BAK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk.bak"
PLATFORM_RELEASE_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-release.apk"
PLATFORM_CURRENT_RELEASE_APK = File.expand_path('tmp/RubotoCore-release.apk', File.dirname(__FILE__))
MANIFEST_FILE = 'AndroidManifest.xml'
GEM_FILE = "ruboto-#{Ruboto::VERSION}.gem"
GEM_SPEC_FILE = 'ruboto.gemspec'
README_FILE = 'README.md'
BLOG_DIR = "#{File.dirname PROJECT_DIR}/ruboto.github.com/_posts"
RELEASE_BLOG = "#{BLOG_DIR}/#{Date.today}-Ruboto-#{Ruboto::VERSION}-release-doc.md"
RELEASE_BLOG_GLOB = "#{BLOG_DIR}/*-Ruboto-#{Ruboto::VERSION}-release-doc.md"

CLEAN.include('ruboto-*.gem', 'tmp')

task :default => :gem

desc 'Generate a gem'
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
    cmd = "gem uninstall -x ruboto -v #{Ruboto::VERSION}"
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

desc 'Generate an example app'
task :example => :install do
  require 'ruboto/sdk_locations'
  EXAMPLE_FILE = File.expand_path("examples/RubotoTestApp_#{Ruboto::VERSION}_tools_r#{Ruboto::SdkLocations::ANDROID_TOOLS_REVISION}.tgz", File.dirname(__FILE__))
  EXAMPLES_GLOB = "#{EXAMPLE_FILE.slice(/^.*?_\d+\.\d+\.\d+/)}*"
  sh "git rm #{EXAMPLES_GLOB}" unless Dir[EXAMPLES_GLOB].empty?
  puts "Creating example app #{EXAMPLE_FILE}"
  app_name = 'RubotoTestApp'
  Dir.chdir File.dirname(EXAMPLE_FILE) do
    FileUtils.rm_rf app_name
    sh "ruboto gen app --package org.ruboto.test_app --name #{app_name} --path #{app_name}"
    Dir.chdir "#{app_name}/test" do
      sh 'ant instrument' # This will also build the main project.
    end
    sh "tar czf #{EXAMPLE_FILE} #{app_name}"
    FileUtils.rm_rf app_name
  end
end

class String
  def wrap(indent = 0)
    scan(/\S.{0,72}\S(?=\s|$)|\S+/).join("\n" + ' ' * indent)
  end
end

desc 'Update the README with the Ruboto description.'
file README_FILE => 'lib/ruboto/description.rb' do
  File.write(README_FILE, File.read(README_FILE).sub(/(?<=\n\n).*(?=\nInstallation)/m, Ruboto::DESCRIPTION))
end

desc 'Generate release docs for a given milestone'

def get_github_issues
  puts 'GitHub login:'
  begin
    require 'rubygems'
    require 'highline/import'
    user = ask('login   : ') { |q| q.echo = true }
    pass = ask('password: ') { |q| q.echo = '*' }
  rescue Exception
    print 'user name: '; user = STDIN.gets.chomp
    print ' password: '; pass = STDIN.gets.chomp
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
  puts milestones.map { |m| "#{'%2d' % m['number']} #{m['title']}" }.join("\n")

  if defined? ask
    milestone = ask('milestone: ', Integer) { |q| q.echo = true }
  else
    print 'milestone: '; milestone = STDIN.gets.chomp
  end

  uri = URI("#{base_uri}/issues?milestone=#{milestone}&state=closed&per_page=1000")
  req = Net::HTTP::Get.new(uri.request_uri)
  req.basic_auth(user, pass)
  res = https.start { |http| http.request(req) }
  issues = YAML.load(res.body).sort_by { |i| i['number'] }
  milestone_name = issues[0] ? issues[0]['milestone']['title'] : "No issues for milestone #{milestone}"
  milestone_description = issues[0] ? issues[0]['milestone']['description'] : "No issues for milestone #{milestone}"
  milestone_description = milestone_description.split("\r\n").map(&:wrap).join("\r\n")
  categories = {
      'Features' => 'feature', 'Bugfixes' => 'bug', 'Support' => 'support',
      'Documentation' => 'documentation', 'Pull requests' => nil,
      'Internal' => 'internal', 'Rejected' => 'rejected', 'Other' => nil
  }
  grouped_issues = issues.group_by do |i|
    labels = i['labels'].map { |l| l['name'] }
    cat = nil
    categories.each do |k, v|
      if labels.include? v
        cat = k
        break
      end
    end
    cat ||= i['pull_request'] && i['pull_request']['html_url'] && 'Pull requests'
    cat ||= 'Other'
    cat
  end
  return categories, grouped_issues, milestone, milestone_description, milestone_name
end

task :release_docs do
  raise "\n    This task requires Ruby 1.9 or newer to parse JSON as YAML.\n\n" if RUBY_VERSION == '1.8.7'
  categories, grouped_issues, milestone, milestone_description, milestone_name = get_github_issues

  puts '=' * 80
  puts
  release_candidate_doc = <<EOF
Subject: [ANN] Ruboto #{milestone_name} release candidate

Hi all!

The Ruboto #{milestone_name} release candidate is now available.

#{milestone_description}

As always we need your help and feedback to ensure the quality of the release.  Please install the release candidate using

    [sudo] gem install ruboto --pre

and test your apps after updating with

    ruboto update app

If you have an app released for public consumption, please let us know.  Our developer program seeks to help developers getting started using Ruboto, and ensure good quality across Ruboto releases.  Currently we are supporting the apps listed here:

    https://github.com/ruboto/ruboto/wiki/Promoted-apps

If you are just starting with Ruboto, but still want to contribute, please select and complete one of the tutorials and mark it with the version of Ruboto you used.

    https://github.com/ruboto/ruboto/wiki/Tutorials-and-examples

If you find a bug or have a suggestion, please file an issue in the issue tracker:

    https://github.com/ruboto/ruboto/issues

--
The Ruboto Team
http://ruboto.org/
EOF

  puts release_candidate_doc
  File.write('RELEASE_CANDICATE_DOC', release_candidate_doc)

  puts
  puts '=' * 80
  puts
  release_doc = <<EOF
Subject: [ANN] Ruboto #{milestone_name} released!

The Ruboto team is pleased to announce the release of Ruboto #{milestone_name}.

#{Ruboto::DESCRIPTION.gsub("\n", ' ').wrap}

New in version #{milestone_name}:

#{milestone_description}

#{(categories.keys & grouped_issues.keys).map do |cat|
    "#{cat}:\n
#{grouped_issues[cat].map { |i| %Q{* Issue ##{i['number']} #{i['title']}}.wrap(2) }.join("\n")}
"
end.join("\n")}
You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=#{milestone}


Installation:

To use Ruboto, you need to install a Ruby implementation.  Then do
(possibly as root/administrator)

    gem install ruboto
    ruboto setup

To create a project do

    ruboto gen app --package <your.package.name>
    cd <project directory>
    ruboto setup

To run an emulator for your project

    cd <project directory>
    ruboto emulator

To run your project

    cd <project directory>
    rake install start

You can find an introductory tutorial at
https://github.com/ruboto/ruboto/wiki

If you have any problems or questions, come see us at http://ruboto.org/

Enjoy!


--
The Ruboto Team
http://ruboto.org/
EOF

  puts release_doc
  puts
  puts '=' * 80

  unless Gem::Version.new(Ruboto::VERSION).prerelease?
    header = <<EOF
---
title : Ruboto #{Ruboto::VERSION}
layout: post
---
EOF
    File.write('RELEASE_DOC', release_doc)
    Dir.chdir BLOG_DIR do
      output = `git status --porcelain`
      old_blog_posts = Dir[RELEASE_BLOG_GLOB] - [RELEASE_BLOG]
      sh "git rm -f #{old_blog_posts.join(' ')}" unless old_blog_posts.empty?
      File.write(RELEASE_BLOG, header + release_doc)
      sh "git add -f #{RELEASE_BLOG}"
      if output.empty?
        `git commit -m "* Added release blog for Ruboto #{Ruboto::VERSION}"`
        sh 'git push'
      else
        puts "Workspace not clean!\n#{output}"
      end
    end
  end
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

  counts_per_month = Hash.new { |h, k| h[k] = Hash.new { |mh, mk| mh[mk] = 0 } }
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
      counts.delete_if { |date_str, count| count == 0 }
      counts.each do |date_str, count|
        date = Date.parse(date_str)
        counts_per_month[date.year][date.month] += count
        total += count
      end
      print '.'; STDOUT.flush
    end
    puts
  end

  puts "\nDownloads statistics per month:"
  years = counts_per_month.keys
  puts "\n    #{years.map { |year| '%6s:' % year }.join(' ')}"
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
  puts '    ' + years.map { |year| '%-12s' % year }.join
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
  puts '    ' + years.map { |year| '%-12s' % year }.join

  puts "\nTotal: #{total}\n\n"
end

desc 'Push the gem to RubyGems'
task :release => [:clean, README_FILE, :release_docs, :gem] do
  output = `git status --porcelain`
  raise "Workspace not clean!\n#{output}" unless output.empty?
  sh "git tag #{Ruboto::VERSION}"
  sh 'git push --tags'
  sh "gem push #{GEM_FILE}"
  Rake::Task[:example].invoke
  sh "git add #{EXAMPLE_FILE}"
  sh "git commit -m '* Added example app for Ruboto #{Ruboto::VERSION} tools r#{Ruboto::SdkLocations::ANDROID_TOOLS_REVISION}' \"#{EXAMPLES_GLOB}\""
  sh 'git push'
end

desc "Run the tests.  Select which test files to load with 'rake test TEST=test_file_pattern'"
task :test do
  FileUtils.rm_rf Dir['tmp/RubotoTestApp_template*']
  test_pattern = ARGV.grep(/^TEST=.*$/)
  ARGV.delete_if { |a| test_pattern.include? a }
  test_pattern.map! { |t| t[5..-1] }
  $: << File.expand_path('test', File.dirname(__FILE__))
  (test_pattern.any? ? test_pattern : %w(test/*_test.rb)).map { |d| Dir[d] }.flatten.each do |f|
    require f.chomp('.rb')[5..-1]
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
    sh "git clone --depth 1 https://github.com/ruboto/ruboto-core.git #{PLATFORM_PROJECT}"
    Dir.chdir PLATFORM_PROJECT do
      sh "ruby -rubygems -I#{File.expand_path('lib', File.dirname(__FILE__))} ../../bin/ruboto update app"
    end
  end

  desc 'Generate a Ruboto Core platform debug apk'
  task :debug => PLATFORM_DEBUG_APK

  task PLATFORM_DEBUG_APK do
    Rake::Task[PLATFORM_PROJECT].invoke
    Dir.chdir(PLATFORM_PROJECT) do
      if File.exists?(PLATFORM_DEBUG_APK_BAK)
        FileUtils.cp PLATFORM_DEBUG_APK_BAK, PLATFORM_DEBUG_APK
      else
        FileUtils.rm PLATFORM_DEBUG_APK
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
    FileUtils.mkdir_p File.dirname(PLATFORM_CURRENT_RELEASE_APK)
    puts 'Downloading the current RubotoCore platform release apk'
    uri = URI('http://ruboto.org/downloads/RubotoCore-release.apk')
    begin
      http = Net::HTTP.new(uri.host, uri.port)
      content = http.request(Net::HTTP::Get.new(uri.request_uri)).body
      File.open(PLATFORM_CURRENT_RELEASE_APK, 'wb') { |f| f << content }
    rescue Exception, SystemExit
      FileUtils.rm(PLATFORM_CURRENT_RELEASE_APK) if File.exists?(PLATFORM_CURRENT_RELEASE_APK)
      raise
    end
  end

  desc 'Install the current RubotoCore platform release apk'
  task :current => PLATFORM_CURRENT_RELEASE_APK do
    install_apk
  end

  desc 'Install the Ruboto Core platform debug apk'
  task :install => PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake install'
    end
  end

  desc 'Uninstall the Ruboto Core platform debug apk'
  task :uninstall do
    uninstall_apk
  end

  private

  def package
    'org.ruboto.core'
  end

  def install_apk
    failure_pattern = /^Failure \[(.*)\]/
    success_pattern = /^Success/
    case package_installed?
    when true
      puts "Package #{package} already installed."
      return
    when false
      puts "Package #{package} already installed, but of different size.  Replacing package."
      output = `adb install -r #{PLATFORM_CURRENT_RELEASE_APK} 2>&1`
      if $? == 0 && output !~ failure_pattern && output =~ success_pattern
        return
      end
      case $1
      when 'INSTALL_PARSE_FAILED_INCONSISTENT_CERTIFICATES'
        puts 'Found package signed with different certificate.  Uninstalling it and retrying install.'
      else
        puts "'adb install' returned an unknown error: (#$?) #{$1 ? "[#$1}]" : output}."
        puts "Uninstalling #{package} and retrying install."
      end
      uninstall_apk
    end
    puts "Installing package #{package}"
    install_retry_count = 0
    begin
      output = nil
      timeout 180 do
        install_start = Time.now
        output = `adb install #{PLATFORM_CURRENT_RELEASE_APK} 2>&1`
        puts "Install took #{(Time.now - install_start).to_i}s."
      end
    rescue TimeoutError
      puts 'Install of current RubotoCore timed out.'
      install_retry_count += 1
      if install_retry_count <= 3
        puts 'Retrying.'
        retry
      end
      puts 'Retrying one final time...'
      install_start = Time.now
      output = `adb install #{PLATFORM_CURRENT_RELEASE_APK} 2>&1`
      puts "Install took #{(Time.now - install_start).to_i}s."
    end
    puts output
    raise "Install failed (#{$?}) #{$1 ? "[#$1}]" : output}" if $? != 0 || output =~ failure_pattern || output !~ success_pattern
  end

  def uninstall_apk
    return if package_installed?.nil?
    puts "Uninstalling package #{package}"
    system "adb uninstall #{package}"
    if $? != 0 && package_installed?
      puts "Uninstall failed exit code #{$?}"
      exit $?
    end
  end

  def package_installed?
    package_name = package
    %w( -0 -1 -2).each do |i|
      path = "/data/app/#{package_name}#{i}.apk"
      o = `adb shell ls -l #{path}`.chomp
      if o =~ /^-rw-r--r-- system\s+system\s+(\d+) \d{4}-\d{2}-\d{2} \d{2}:\d{2} #{File.basename(path)}$/
        apk_file = PLATFORM_CURRENT_RELEASE_APK
        if !File.exists?(apk_file) || $1.to_i == File.size(apk_file)
          return true
        else
          return false
        end
      end

      sdcard_path = "/mnt/asec/#{package_name}#{i}/pkg.apk"
      o = `adb shell ls -l #{sdcard_path}`.chomp
      if o =~ /^-r-xr-xr-x system\s+root\s+(\d+) \d{4}-\d{2}-\d{2} \d{2}:\d{2} #{File.basename(sdcard_path)}$/
        apk_file = PLATFORM_CURRENT_RELEASE_APK
        if !File.exists?(apk_file) || $1.to_i == File.size(apk_file)
          return true
        else
          return false
        end
      end
    end
    return nil
  end

end

desc 'Download the latest jruby-jars snapshot'
task :get_jruby_jars_snapshot do
  current_gem = 'jruby-jars-1.7.5.dev.gem'
  `wget http://ci.jruby.org/snapshots/master/#{current_gem}`
  jars = Dir["#{current_gem}.*"]
  jars[0..-2].each { |j| FileUtils.rm_f j } if jars.size > 1
  FileUtils.mv(jars[-1], current_gem) if jars[-1]
end
