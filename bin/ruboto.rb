#!/usr/bin/env ruby

require 'main'
require 'fileutils'

class AssetCopier
  def initialize(from, to)
    @from = from
    @to = to
  end

  def copy(from, to='')
    FileUtils.cp_r(Dir[File.join(@from, from)], File.join(@to, to))
  end
end




Main {
  mode "gen app" do
    option("name"){
      required
      argument :required
      description "Name of your app"
    }
    option("target") {
      required
      argument :required
      description "android version to target. must begin with 'android-'. Ex: android-8 to target Froyo"
    }
    option("path"){
      required
      argument :required
      description "path to where you want your app."
    }
    option("package"){
      required
      argument :required
      description "Name of package. Must be unique for every app. A common pattern is yourtld.yourdomain.appname (Ex. org.ruboto.irb)"
    }

    def run
      path = params['path'].value
      name = params['name'].value
      target = params['target'].value
      package = params['package'].value
      `android create project -n #{name} -t #{target} -p #{path} -k #{package} -a RubotoActivity`
      root = File.expand_path(path)
      assets = File.expand_path(__FILE__ + "/../../assets")

      copier = AssetCopier.new assets, root
      copier.copy "Rakefile"
      copier.copy "libs"
      copier.copy ".gitignore"
      copier.copy "lib"
      copier.copy "assets"
      copier.copy "src/*.java", "src/#{package.gsub('.', '/')}"

      java_files = Dir[File.join(root, "src/#{package.gsub('.', '/')}/*.java")]
      java_files.each do |file|
        text = File.read(file)
        File.open(file, 'w') do |f|
          f << text.gsub("org.ruboto", package)
        end
      end
    end
  end
}

