$:.unshift('lib') unless $:.include?('lib')
require 'time'
require 'date'
require 'rake/clean'
require 'rexml/document'
require 'ruboto/version'
require 'ruboto/description'
require 'ruboto/sdk_versions'
require 'uri'
require 'net/http'
require 'net/https'
require 'openssl'
require 'yaml'
require_relative 'assets/rakelib/ruboto.device'

PLATFORM_PROJECT = File.expand_path('tmp/RubotoCore', File.dirname(__FILE__))
PLATFORM_PACKAGE = 'org.ruboto.core'
PLATFORM_DEBUG_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk"
PLATFORM_DEBUG_APK_BAK = "#{PLATFORM_PROJECT}/bin/RubotoCore-debug.apk.bak"
PLATFORM_RELEASE_APK = "#{PLATFORM_PROJECT}/bin/RubotoCore-release.apk"
PLATFORM_CURRENT_RELEASE_APK = File.expand_path('tmp/RubotoCore-release.apk', File.dirname(__FILE__))
MANIFEST_FILE = 'AndroidManifest.xml'
GEM_FILE = "ruboto-#{Ruboto::VERSION}.gem"
GEM_SPEC_FILE = 'ruboto.gemspec'
README_FILE = 'README.md'
WEB_DIR = File.expand_path('../ruboto.github.com', File.dirname(__FILE__))
BLOG_DIR = '_posts'
RELEASE_BLOG = "#{BLOG_DIR}/#{Date.today}-Ruboto-#{Ruboto::VERSION}-release-doc.md"
RELEASE_BLOG_GLOB = "#{BLOG_DIR}/*-Ruboto-#{Ruboto::VERSION}-release-doc.md"
RELEASE_CANDIDATE_DOC = 'RELEASE_CANDICATE_DOC.md'
RELEASE_DOC = 'RELEASE_DOC.md'

CLEAN.include('**/*~', 'ruboto-*.gem', 'tmp')
CLOBBER.include('adb_logcat.log', 'jruby-jars-*.gem')

task :default => :gem

desc 'Generate a gem'
task :gem => GEM_FILE

file GEM_FILE => GEM_SPEC_FILE do
  puts "Generating #{GEM_FILE}"
  `gem build #{GEM_SPEC_FILE}`
end

task :install => :gem do
  old_rubyopt = ENV['RUBYOPT']
  ENV['RUBYOPT'] = nil
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
  ENV['RUBYOPT'] = old_rubyopt
end

task :uninstall do
  old_rubyopt = ENV['RUBYOPT']
  ENV['RUBYOPT'] = nil
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
  ENV['RUBYOPT'] = old_rubyopt
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
    Dir.chdir app_name do
      sh 'rake patch_dex'
      Dir.chdir 'test' do
        sh 'ant instrument' # This will also build the main project.
      end
    end
    sh "tar czf #{EXAMPLE_FILE} #{app_name}"
    FileUtils.rm_rf app_name
  end
end

class String
  def wrap(indent = 0)
    line_length = 72-indent
    scan(/\S.{0,#{line_length}}\S(?=\s|$)|\S+/).join("\n" + ' ' * indent)
  end
end

desc 'Update the README with the Ruboto description.'
file README_FILE => 'lib/ruboto/description.rb' do
  File.write(README_FILE, File.read(README_FILE).sub(/(?<=\n\n).*(?=\nInstallation)/m, Ruboto::DESCRIPTION))
end

def get_github_issues
  host = 'api.github.com'
  base_uri = "https://#{host}/repos/ruboto/ruboto"
  https = Net::HTTP.new(host, 443)
  https.use_ssl = true
  https.verify_mode = OpenSSL::SSL::VERIFY_NONE

  milestone_uri = URI("#{base_uri}/milestones")
  req = Net::HTTP::Get.new(milestone_uri.request_uri)
  res = https.start { |http| http.request(req) }
  milestones = YAML.load(res.body).sort_by { |i| Date.parse(i['due_on']) }
  milestone_entry = milestones.find { |m| m['title'] == Ruboto::VERSION.chomp('.dev') }
  raise "Milestone for version #{Ruboto::VERSION} not found." unless milestone_entry
  milestone = milestone_entry['number']

  uri = URI("#{base_uri}/issues?milestone=#{milestone}&state=all&per_page=1000")
  req = Net::HTTP::Get.new(uri.request_uri)
  res = https.start { |http| http.request(req) }
  issues = YAML.load(res.body).sort_by { |i| i['number'] }
  milestone_name = issues[0] ? issues[0]['milestone']['title'] : "No issues for milestone #{milestone}"
  milestone_description = issues[0] ? issues[0]['milestone']['description'] : "No issues for milestone #{milestone}"
  milestone_description = milestone_description.split("\r\n").map(&:wrap).join("\n")
  categories = {
      'API Changes' => 'API change', 'Features' => 'feature',
      'Bugfixes' => 'bug', 'Performance' => 'performance',
      'Documentation' => 'documentation', 'Support' => 'support',
      'Community' => 'community', 'Pull requests' => nil,
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

desc 'Generate release docs for a given milestone'
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
  File.write(RELEASE_CANDIDATE_DOC, release_candidate_doc)
  sh "git add -f #{RELEASE_CANDIDATE_DOC}"

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
#{grouped_issues[cat].map { |i| %Q{* Issue ##{i['number']} #{i['title'].gsub('`', "'")}#{" (#{i['user']['login']})" if i['pull_request'] && i['pull_request']['html_url']}}.wrap(2) }.join("\n")}
"
end.join("\n")}
You can find a complete list of issues here:

* https://github.com/ruboto/ruboto/issues?state=closed&milestone=#{milestone}


Installation:

To use Ruboto, you need to install a Ruby implementation.  Then do
(possibly as root/administrator)

    gem install ruboto
    ruboto setup -y

To create a project do

    ruboto gen app --package <your.package.name>
    cd <project directory>
    ruboto setup -y

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
  File.write(RELEASE_DOC, release_doc)

  unless Gem::Version.new(Ruboto::VERSION).prerelease?
    header = <<EOF
---
title : Ruboto #{Ruboto::VERSION}
layout: post
category: news
---
EOF
    Dir.chdir WEB_DIR do
      output = `git status --porcelain`
      old_blog_posts = Dir[RELEASE_BLOG_GLOB] - [RELEASE_BLOG]
      sh "git rm -f #{old_blog_posts.join(' ')}" unless old_blog_posts.empty?
      File.write(RELEASE_BLOG, header + release_doc)
    end
  end
end

desc 'Fetch download stats form rubygems.org'
task :stats do
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
  Dir.chdir WEB_DIR do
    sh "git add -f #{RELEASE_BLOG}"
    `git commit -m "* Added release blog for Ruboto #{Ruboto::VERSION}" -- #{RELEASE_BLOG}`
    output = `git status --porcelain`
    raise "Web workspace not clean!\n#{output}" unless output.empty?
    sh 'git push'
  end
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
  test_files = (test_pattern.any? ? test_pattern : %w(test/*_test.rb)).
      map { |d| Dir[d] }.flatten.sort
  if /(\d+)OF(\d+)/i =~ ENV['TEST_PART']
    part_index = $1.to_i - 1
    parts = $2.to_i
    total_tests = test_files.size
    files_in_part = total_tests.to_f / parts
    start_index = (files_in_part * part_index).round
    end_index = (files_in_part * (part_index + 1)).round - 1
    test_files = test_files[start_index..end_index]
    puts "Running tests #{start_index + 1}-#{end_index + 1} of #{total_tests}"
  end
  test_files.each do |f|
    require f.chomp('.rb')[5..-1]
  end
end

namespace :platform do
  desc 'Remove Ruboto Core platform project'
  task :clean do
    FileUtils.rm_rf PLATFORM_PROJECT
  end

  desc 'Generate the Ruboto Core platform project'
  task project: PLATFORM_PROJECT

  file PLATFORM_PROJECT do
    sh "git clone --depth 1 https://github.com/ruboto/ruboto-core.git #{PLATFORM_PROJECT}"
    Dir.chdir PLATFORM_PROJECT do
      sh "ruby -rubygems -I#{File.expand_path('lib', File.dirname(__FILE__))} ../../bin/ruboto update app --force"
    end
  end

  desc 'Generate a Ruboto Core platform debug apk'
  task debug: PLATFORM_DEBUG_APK

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
  task release: PLATFORM_RELEASE_APK

  file PLATFORM_RELEASE_APK => PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake release'
    end
  end

  desc 'Download the current RubotoCore platform release apk'
  file PLATFORM_CURRENT_RELEASE_APK do
    FileUtils.mkdir_p File.dirname(PLATFORM_CURRENT_RELEASE_APK)
    puts 'Downloading the current RubotoCore platform release apk'
    uri = URI('https://raw.github.com/ruboto/ruboto.github.com/master/downloads/RubotoCore-release.apk')
    begin
      headers = {'User-Agent' => 'Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; de-at) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10'}
      catch :download_ok do
        loop do
          Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https',
              :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
            response = http.get(uri.request_uri, headers)
            if response.code == '200'
              File.open(PLATFORM_CURRENT_RELEASE_APK, 'wb') { |f| f << response.body }
              throw :download_ok
            elsif response.code == '301' || response.code == '302'
              headers.update('Referer' => uri.to_s)
              if (cookie = response.response['set-cookie'])
                headers.update('Cookie' => cookie)
              end
              uri = URI(response['location'].gsub(/^\//, 'http://ruboto.org/'))
              puts "Following redirect to #{uri}."
            else
              puts "Got an unexpected response (#{response.code}).  Retrying download."
              puts response.inspect
              sleep 1
            end
          end
        end
      end
    rescue Exception, SystemExit
      puts "Download failed: #{$!}"
      FileUtils.rm(PLATFORM_CURRENT_RELEASE_APK) if File.exists?(PLATFORM_CURRENT_RELEASE_APK)
      raise
    end
  end

  desc 'Install the current RubotoCore platform release apk'
  task current: PLATFORM_CURRENT_RELEASE_APK do
    install_apk PLATFORM_PACKAGE, PLATFORM_CURRENT_RELEASE_APK
  end

  desc 'Install the Ruboto Core platform debug apk'
  task install: PLATFORM_PROJECT do
    Dir.chdir(PLATFORM_PROJECT) do
      sh 'rake install'
    end
  end

  desc 'Uninstall the Ruboto Core platform debug apk'
  task :uninstall do
    uninstall_apk(PLATFORM_PACKAGE, PLATFORM_CURRENT_RELEASE_APK)
  end

end

desc 'Download the latest jruby-jars snapshot'
task :get_jruby_jars_snapshots do
  download_host = 's3.amazonaws.com'
  download_dir = "/ci.jruby.org"
  index = Net::HTTP.get(download_host, download_dir)
  all_gems = index.scan(%r{jruby-jars-.*?.gem}).sort_by{|v| Gem::Version.new(v[11..-5])}
  master_gem = all_gems.last
  stable_gems = all_gems.grep /-1\.7\./
  stable_gem = stable_gems.last
  FileUtils.rm_rf Dir['jruby-jars-*.gem']
  [[master_gem, 'master'], [stable_gem, 'jruby-1_7']].each do |gem, branch|
    print "Downloading #{gem}: \r"
    uri = URI("http://#{download_host}#{download_dir}/snapshots/#{branch}/#{gem}")
    Net::HTTP.new(uri.host, uri.port).request_get(uri.path) do |response|
      if response.code == '200'
        length = response['Content-Length'].to_i
        timestamp = response['Last-Modified'] # Sat, 23 Jan 2016 05:52:03 GMT'
        body = ''
        done = 0
        response.read_body do |fragment|
          body << fragment
          done += fragment.length
          unless length == 0
            progress = (done * 100) / length
            print "Downloading #{gem}: #{done / 1024}/#{length / 1024}KB #{progress}%\r"
          end
        end
        unless body.empty?
          File.write(gem, body)
          FileUtils.touch gem, mtime: Time.parse(timestamp)
        end
        puts
      else
        raise "Unexpected HTTP response code: #{response.code.inspect}"
      end
    end
  end
end

def test_parts(api)
  (api == 23) ? 6 : 3
end

task '.travis.yml' do
  puts "Regenerating #{'.travis.yml'}"
  source = File.read('.travis.yml')
  matrix = ''
  allow_failures = ''

  # FIXME(uwe):  JRuby 1.7.13 works for Nettbuss.  Keep for 2017.
  # FIXME(uwe):  Test all of these that work
  [
      # ['CURRENT', [nil]],                # Running standalone is the most important way now
      # ['FROM_GEM', [:MASTER, :STABLE]], # Running standalone is the most important way now
      ['STANDALONE', [:MASTER, :STABLE, '1.7.25', '1.7.13']],
  ].each do |platform, versions|
    versions.each do |v|
      # FIXME(uwe):  Test the newest and most common api levels
      # FIXME(uwe):  Nettbuss uses api level 15.  Keep for 2017.
      # FIXME(uwe):  https://github.com/ruboto/ruboto/issues/426
      [25, 24, 23, 22, 21, 19, 15].each do |api|
        (1..test_parts(api)).each do |n|
          line = "    - ANDROID_TARGET=#{api} RUBOTO_PLATFORM=#{platform.ljust(10)} TEST_PART=#{n}of#{test_parts(api)}#{" JRUBY_JARS_VERSION=#{v}" if v}\n"

          next if v == :MASTER || v == :STABLE
          next if api == 25 # FIXME(uwe):  Remove when Android 7.1 is green.  No runnable ABIs on travis.
          next if api == 24 # FIXME(uwe):  Remove when Android 7.0 is green.  No space left on device on travis.
          next if api == 22 # FIXME(uwe):  Remove when Android 5.1 is green.  Must use slow ARM emulator due to missing HAXM.
          next if api == 22 && platform == 'STANDALONE' && v == :STABLE # FIXME(uwe):  Remove when Android 5.1 is green.  Must use slow ARM emulator due to missing HAXM.
          next if api == 21 # FIXME(uwe):  Remove when Android 5.0 is green.

          next if v == '1.7.13' && api > 19

          (allow_failures << line.gsub('-', '- env:')) if api == 23 # FIXME(uwe):  Remove when Android 6.0 is green.  Unable to start emulator on travis.

          matrix << line
        end
      end
      matrix << "\n"
    end
  end
  matrix_str = "  matrix:\n#{matrix}"
  allow_failures_str = <<EOF # FIXME(uwe)
  allow_failures:
#{allow_failures}
EOF
  File.write('.travis.yml', source.
          sub(/^  matrix:.*?(?=^matrix:)/m, matrix_str).
          sub(/^  allow_failures:.*?(?=^script:)/m, allow_failures_str))
end
