############################################################################
#
# Use to build dependencies within stdlib.
#

class StdlibDependencies
  attr_reader :dependencies, :version

  REQUIRE = %r{^\s*require[ (]['"]([a-zA-Z0-9/-_]+)["'][)]?\s*$}
  REQUIRE_RELATIVE = %r{^\s*require_relative[ (]['"]([a-zA-Z0-9/-_]+)["'][)]?\s*$}

  def self.[](key)
    versions[key]
  end

  def self.versions
    @@versions ||= {}
  end

  def self.collect(dir=".")
    local = new("app")
    Dir.chdir(dir) do 
      local.check_dir(["ruboto"])
    end
    local
  end

  def self.generate(dir=".")
    versions

    Dir.chdir(dir) do
      raise("Can't find shared directory") unless File.directory?("shared") 
      Dir["*"].select{|d| File.directory?(d) && d != "shared"}.each do |d|
        @@versions[d] = new(d).generate
      end
    end

    versions
  end

  def self.dump(file)
    require 'yaml'

    all_dependencies = {}
    versions.each{|k, v| all_dependencies[k] = v.dependencies}

    File.open( file, 'w' ) do |out|
      YAML.dump( all_dependencies, out )
    end

    versions
  end

  def self.load(file)
    require 'yaml'

    @@versions = {}
    raise("Can't find #{file}") unless File.exists?(file) 

    File.open(file) do |versions|
      YAML.load(versions).each{|k,v| @@versions[k] = new(k, v)}
    end

    versions
  end

  def initialize(version, dependencies={})
    @version = version
    @dependencies = dependencies
  end

  def [](key)
    @dependencies[key]
  end

  def generate
    raise("Can't find shared directory") unless File.directory?("shared") 
    raise("Can't find #{@version} directory") unless File.directory?(@version) 

    Dir.chdir("shared"){check_dir}
    Dir.chdir(@version){check_dir}

    # Clean up dependencies
    @dependencies.keys.sort.each do |i|
      # remove duplicates
      @dependencies[i] = @dependencies[i].uniq

      # remove references to self 
      @dependencies[i] = @dependencies[i] - [i]

      # sort 
      @dependencies[i] = @dependencies[i].sort
    end

    self
  end

  def depends_on(name, on=nil)
    base = name[0..-4]
    @dependencies[base] = (@dependencies[base] || [])
    @dependencies[base] << on
  end

  def gather_dependencies(file)
    f = IO.read(file)

    ##################################
    #
    # Handle encoding problems under different rubies
    #
    if String.method_defined?(:encode)
      f.encode!('UTF-8', 'UTF-8', :invalid => :replace)
    else
      require 'iconv'
      f = Iconv.new('UTF-8', 'UTF-8//IGNORE').iconv(f)
    end
    #
    #################################

    f.scan(REQUIRE) do |j|
      depends_on(file, j[0])
    end

    f.scan(REQUIRE_RELATIVE) do |j|
      on = file.split('/')[0..-2] << j[0]
      depends_on(file, on.join('/'))
    end
  end

  def check_dir(exclude=[])
    Dir["**/*.rb"].select{|rb| not exclude.include?(rb.split('/')[0])}.each do |i|
      gather_dependencies(i)
    end
  end
end

