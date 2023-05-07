namespace :apis do
  desc 'Generate a new android_api.xml from the current api descriptions.'
  task :compile do
    $: << '.' unless $:.include?('.')
    require 'rakelib/android_api_gen'

    all = ApiTag.compile_platforms
    print 'Writing results...'
    all.write_to('lib/java_class_gen/android_api.xml')
    puts 'done.'
  end

  desc 'Pull a version of the API descriptions onto the local drive.'
  task :get do
    $: << '.' unless $:.include?('.')
    require 'rakelib/android_api_gen'
    require 'rexml/document'
    require 'open-uri'

    REPOSITORY_BASE = 'https://dl-ssl.google.com/android/repository'
    # Todo: Make sure there is not a newer repository
    REPOSITORY_URL = "#{REPOSITORY_BASE}/repository-12.xml"
    # odoT

    $stdout.sync = true

    mkdir('apis') unless File.exist?('apis')

    print 'Getting 1 (1.0)...'
    file = open(Api.platform_url(1))
    File.open('apis/1.xml', 'w'){|f| f << file.read}
    puts 'done.'

    doc = REXML::Document.new(open(REPOSITORY_URL))
    doc.root.elements.each('sdk:platform') do |i|
      number = i.elements['sdk:api-level'].text.to_i
      print "Getting #{number} (#{i.elements['sdk:version'].text})..."

      url = Api.platform_url(number)
      if url.nil?
        puts 'branch unknown (set branch for current.txt).'
      else
        file = open(url)
        File.open("apis/#{number}.#{url[-3..-1]}", 'w'){|f| f << file.read}
        puts 'done.'
      end
    end
  end
end
