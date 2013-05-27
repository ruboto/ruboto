namespace :apis do
  desc 'Generate a new android_api.xml from the current api descriptions.'
  task :compile do
    require 'rakelib/android_api_gen'

    all = ApiTag.compile_platforms
    print "Writing results..."
    all.write_to("lib/java_class_gen/android_api.xml")
    puts "done."
  end

  desc 'Pull a version of the API descriptions onto the local drive.'
  task :get do
    require 'rexml/document'
    require 'open-uri'

    REPOSITORY_BASE = 'https://dl-ssl.google.com/android/repository'
    # Todo: Make sure there is not a newer repository
    REPOSITORY_URL = "#{REPOSITORY_BASE}/repository-8.xml"
    # odoT

    GITHUB_BASE = 'https://raw.github.com/android/platform_frameworks_base/master/api'

    $stdout.sync = true

    mkdir('platforms') unless File.exists?("platforms")

    print "Getting 1 (1.0)..."
    file = open("#{GITHUB_BASE}/1.xml")
    File.open("apis/1.xml", 'w'){|f| f << file.read}
    puts "done."

    doc = REXML::Document.new(open(REPOSITORY_URL))
    doc.root.elements.each("sdk:platform") do |i|
      print "Getting #{i.elements['sdk:api-level'].text} (#{i.elements['sdk:version'].text})..."
      begin
        file = open("#{GITHUB_BASE}/#{i.elements['sdk:api-level'].text}.xml")
        File.open("apis/#{i.elements['sdk:api-level'].text}.xml", 'w'){|f| f << file.read}
      rescue
        file = open("#{GITHUB_BASE}/#{i.elements['sdk:api-level'].text}.txt")
        File.open("apis/#{i.elements['sdk:api-level'].text}.txt", 'w'){|f| f << file.read}
      end
      puts "done."
    end
  end
end
