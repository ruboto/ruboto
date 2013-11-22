#######################################################
#
# android_api_gen.rb (by Scott Moyer)
#
# This is the code to build the android_api.xml
# file from the X.xml files (where X is 1-13) and
# Y.txt files (where Y is > 13) pulled from the 
# Github's mirror of the AOSP code.
#
# Call: ApiTag.compile_platforms
# Then: write_to(<file>)
#
# This script:
#   1) Determines the API Levels from the Android Repository
#   2) Reads each API description (xml for <= 13, txt >= 14) from either
#        a) The current directory
#        b) The Android Github mirror
#   3) Combines them into a single xml file with information
#        about when components were added, removed, or deprecated
#
#######################################################

require 'strscan'
require 'open-uri'
require 'rexml/document'

$stdout.sync = true

###############################################################################
#
# Calculate the Platform URL
#

class Api
  API_URL_BASE = 'https://raw.github.com/android/platform_frameworks_base/%s/api/%s'

  def self.platform_url(level_int)
    branch  = case level_int
              when 1..17 then 'jb-mr1.1-release'
              ################################
              #
              # Add new api branches
              #
              when 18    then 'jb-mr2-release'
              when 19    then 'kitkat-release'
              #
              ################################
              else       return nil
              end

    file_name = case level_int
              when 1..13  then "#{level_int}.xml"
              when 14..17 then "#{level_int}.txt"
              else             'current.txt'
              end

    API_URL_BASE % [branch, file_name]
  end
end

###############################################################################
#
# Tag and CoreTag classes: These do most of the work for the children
#

class Tag
  def self.children_types; @children_types ||= []; end
  def self.children_classes; @children_classes ||= []; end
  def self.child_tags *args; args.each{|i| child_tag i}; end

  def self.default_values(hash); @default_value_hash = hash; end
  def self.default_value_hash; @default_value_hash || {}; end

  def self.child_tag text
    children_types << text
    children_classes << eval("#{text.capitalize}Tag")

    define_method("add_#{text}"){|p| children_of_tag(text) << p}
    define_method("#{text}_list") {children_of_tag(text)}
    define_method("#{text}_names") {children_of_tag(text).map{|i| i.identifier}}
    define_method("#{text}_named"){|name| children_of_tag(text).find{|i| i.identifier == name}}
  end

  def initialize(api, *args)
    @children = []
    self.class.children_types.each {|i| @children << []}

    @values = args[1] || {}
    @values['deprecated'] = (api || self).api_level if @values['deprecated'] == 'deprecated'
    self.class.default_value_hash.each{|k,v| @values.delete(k) if @values[k] == v}

    api == self ? tag_start(*args) : tag_start(api, *args)
  end

  def method_missing name, *args
    n = name.to_s
    if n[-1..-1] == '?'
      n = n[0..-2]
      return @values[n] == 'true' if @values
    end
    return @values[n] if @values
    super(name, *args)
  end

  def children_of_tag name; @children[self.class.children_types.index(name)]; end
  def identifier; name.to_s; end

  def full_identifier(parent_identifier=nil)
    parent_identifier ? "#{parent_identifier}.#{identifier}" : identifier
  end

  def tag_start(api, *args)
    return if args[0] == self.class.name[0..-4].downcase
    if (i = self.class.children_types.index(args[0]))
      # puts "tag_start: #{args.map {|x| x.inspect}.join(', ')}"
      @children[i] << (@current = self.class.children_classes[i].new(api || self, *args))
    else
      puts "***Error*** tag_start: #{args.map {|x| x.inspect}.join(', ')}" unless @current
      @current.tag_start(api || self, *args)
    end
  end

  def type
    return @values['type'] if @values and @values['type']
    super
  end

  def add_value name, value, replace=false
    @values ||= {}
    @values[name] = value if @values[name].nil? or replace
  end

  def add_value_to_core(name, value, replace=false); end
  def merge_with(other, api); end

  def write_to(doc)
    new_values = {}
    @values.each{|k,v| new_values[k.to_s] = v}
    element = doc.add_element self.class.name[0..-4].downcase, new_values
    @children.flatten.each{|i| i.write_to element}
  end
end

class CoreTag < Tag
  def add_value_to_core name, value, replace=false
    add_value name, value, replace
    @children.each{|i| i.each{|j| j.add_value_to_core(name, value,replace)}}
  end

  def merge_with other, api
    add_value('deprecated', api.api_level, true) if other.deprecated and not deprecated

    self.class.children_types.each_with_index do |tag_type, index|
      if self.class.children_classes[index].superclass == CoreTag
        (self.send("#{tag_type}_names") - other.send("#{tag_type}_names")).each do |i|
          self.send("#{tag_type}_named", i).add_value_to_core 'api_removed', api.api_level
        end
        (self.send("#{tag_type}_names") & other.send("#{tag_type}_names")).each do |i|
          self.send("#{tag_type}_named", i).merge_with other.send("#{tag_type}_named", i), api
        end
        (other.send("#{tag_type}_names") - self.send("#{tag_type}_names")).each do |i|
          self.send("add_#{tag_type}", other.send("#{tag_type}_named", i))
        end
      end
    end
  end
end

###############################################################################
#
# Tag children that represent the actual xml tags for the API
#

class ApiidTag < Tag; end
class ImplementsTag < Tag; end
class ParameterTag < Tag; end
class ExceptionTag < Tag; end

class FieldTag < CoreTag
  default_values({
      'transient'  => 'false',
      'final'      => 'false',
      'static'     => 'false',
      'deprecated' => 'not deprecated',
      'volatile'   => 'false',
      'visibility' => 'public'
  })

  # Need to read fields, but don't need to write them
  def write_to(doc);end
end

class ConstructorTag < CoreTag
  child_tags 'parameter', 'exception'
  default_values({
      'final'      => 'false',
      'static'     => 'false',
      'deprecated' => 'not deprecated',
      'visibility' => 'public'
  })
end

class MethodTag < CoreTag
  child_tags 'parameter', 'exception'
  default_values({
      'final'        => 'false',
      'synchronized' => 'false',
      'native'       => 'false',
      'abstract'     => 'false',
      'static'       => 'false',
      'deprecated'   => 'not deprecated',
      'visibility'   => 'public',
      'return'       => 'void'
  })

  # Identify a class by its name and parameters
  def identifier
    "#{name}(#{@children[0].map{|i| i.type}.join(',')})"
  end
end

class ClassTag < CoreTag
  child_tags 'implements', 'constructor', 'field', 'method'
  default_values({
      'final'      => 'false',
      'abstract'   => 'false',
      'static'     => 'false',
      'deprecated' => 'not deprecated',
      'visibility' => 'public'
  })
end

class InterfaceTag < CoreTag
  child_tags 'implements', 'field', 'method'
  default_values({
      'final'      => 'false',
      'abstract'   => 'false',
      'static'     => 'false',
      'deprecated' => 'not deprecated',
      'visibility' => 'public'
  })
end

class PackageTag < CoreTag
  child_tags 'class', 'interface'
end

###############################################################################
#
# Represents a API level or builds a combined set of APIs
#

class ApiTag < CoreTag
  attr_reader :number
  child_tags 'apiid', 'package'

  def self.compile_platforms()
    #Todo: Check to see if there is a newer repository
    doc = REXML::Document.new(open('https://dl-ssl.google.com/android/repository/repository-8.xml'))
    #odoT

    # Look up the platform version names and max platform api_level
    max_platform = 1
    versions = {'1' => '1.0'}
    doc.root.elements.each('sdk:platform') do |i|
      api_level = i.elements['sdk:api-level'].text.to_i
      versions[api_level.to_s] = i.elements['sdk:version'].text
      max_platform = api_level if api_level > max_platform
    end
    puts "Highest API Level is #{max_platform}"

    # Scan all the platform description files
    first = current = nil
    1.upto(max_platform) do |i|
      print "Scanning #{i}..."
      c = self.new('api', {}).read_platform(i)
      unless c
        # The platform description file doesn't exist (may not have been released yet)
        puts 'not found.'
        break
      end

      current = c
      if first
        current.api_stamp
        print 'merging...'
        first.merge_with current, current
      end
      first ||= current
      puts 'done.'
    end

    # Build the api descritions
    codes = current.package_named('android.os').class_named('Build.VERSION_CODES')
    codes.field_names.each do |name|
      field = codes.field_named(name)
      if field.value != '10000'
        apiid_values = {'number' => field.value,
                        'name' => name.gsub(/([A-Z]+)(_|$)/){$1.capitalize + ($2 == '_' ? ' ' : '')}.gsub('_', '.'),
                        'version' => versions[field.value]}
        puts apiid_values.inspect
        first.add_apiid(ApiidTag.new(first, 'apiid', apiid_values))
      end
    end

    first
  end

  def doc
    @doc
  end

  def read_platform(number)
    @number = number

    if File.exists?("apis/#{@number}.txt")
      read_platform_from_txt(IO.read("apis/#{@number}.txt"))
    elsif File.exists?("apis/#{@number}.xml")
      read_platform_from_xml(IO.read("apis/#{@number}.xml"))
    else
      url = Api.platform_url(number)
      return nil if url.nil?
      
      if url[-3..-1] == 'xml'
        read_platform_from_xml(open(url).read)
      else
        read_platform_from_txt(open(url).read)
      end

    end

    self
  end

  def read_platform_from_xml(file)
    doc = StringScanner.new(file)
    until doc.eos?
      doc.scan(/\s*</)
      unless doc.scan(/\/\w+>\s*/)
        name = doc.scan(/\w+/)
        doc.scan(/\s+/)
        values = {}
        until doc.scan(/[\/>]/)
          key = doc.scan(/\w+/)
          doc.scan(/="/)
          value = doc.scan(/[^"]*/)
          doc.scan(/"\s*/)
          values[key] = value.include?('&') ? value.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', "\"") : value
          doc.scan(/\s*/)
        end
        doc.scan(/>\s*/)
        # Need to keep field because we want to read the Build.VERSION information
        # tag_start(name, values) unless %w(field implements).include?(name)   
        tag_start(name, values) unless %w(implements).include?(name)
      end
    end
  end

  def read_platform_from_txt(file)
    @doc = StringScanner.new(file)
    tag_start('api', {})
    package_name = ''

    while package_name
      package_name = read_package
    end
  end

  def write_to file_name
    d = REXML::Document.new
    super d
    d.write(File.open(file_name, 'w'))
    d
  end

  def api_stamp; add_value_to_core 'api_added', @number.to_s;  end
  def api_level; @number.to_s; end
  def identifier; "android-#{@number}"; end
  def initialize(*args); super(self, *args); end
  def tag_start(*args); super(self, *args); end

  #
  # Code for scanning txt files (API Level > 13)
  #

  def current_package
    @current_package
  end

  def read_package
    doc.scan(/package\s([^\s]+)\s\{\s+/)
    return nil if doc[1].nil? or doc[1] == ''
    @current_package = doc[1]

    tag_start('package', {'name' => doc[1]})

    while read_class_or_interface != '}' and !doc.eos?
    end

    return '}'
  end

  def read_class_or_interface
    if doc.scan(/\}\s*/) or doc.eos?
      return '}'
    else
      doc.scan(/(public|protected)?([a-z\s]*)\s(class|interface)\s([^\s]+)\s(extends\s([^\s]+)\s)?(implements\s([^\{]+))?\{\s+/)
      visibility, modifiers, type, name, extends, implements = doc[1], doc[2], doc[3], doc[4], doc[6], doc[8]

      # Handle the special case when they fail to put public or private in front of a class
      unless modifiers
        doc.scan(/(class|interface)\s([^\s]+)\s(extends\s([^\s]+)\s)?(implements\s([^\{]+))?\{\s+/)
        type, name, extends, implements = doc[1], doc[2], doc[3], doc[5], doc[7]
        visibility = 'public'
        modifiers = ''
      end

      modifiers = modifiers.strip.split(' ')

      values = {
          'deprecated' => modifiers.include?('deprecated') ? 'deprecated' : 'not deprecated',
          'visibility' => (visibility == nil ? 'public' : visibility), #missing for some reason
          'name'       => name,
      }

      values['extends'] = extends ? extends : 'java.lang.Object'
      # ignore implements

      %w(final abstract static).each do |i|
        values[i] = modifiers.include?(i).to_s
      end

      tag_start(type, values)

      while read_method_or_field != '}' and !doc.eos?
      end

      return nil
    end 
  end

  def read_method_or_field
    return '}' if doc.scan(/\}\s*/)
     
    doc.scan(/(\w+)\s/)
    case(doc[1])
    when 'ctor' then read_ctor
    when 'field' then read_field
    when 'method' then read_method
    when 'enum_constant' then read_enum_constant
    end

    nil
  end

  def read_ctor
    doc.scan(/(\w+)\s+([^\(]*)\(([^\)]*)\).*$\s*/)
    visibility, name, params = doc[1], doc[2], doc[3]

    tag_start('constructor', {
        'final' => 'false',
        'static' => 'false',
        'deprecated' => 'not deprecated',
        'visibility' => visibility,
        'name' => name,
        'type' => "#{@current_package}.#{name}"
    })

    params.split(', ').each_with_index do |p, i|
      tag_start('parameter', {'name' => "arg#{i}", 'type' => p})
    end
  end

  def read_field
    visibility = doc.scan(/\w+/)
    doc.scan(/\s+/)
    rest = doc.scan(/.*$\s*/)
    flags = %w(transient final static deprecated volatile) & rest.split(' ')
    data =  rest.split(' ') - %w(transient final static deprecated volatile)
    type = data[0]
    name = data [1][-1..-1] == ';' ? data [1][0..-2] : data [1]

    if data.size == 2
      value = nil
    elsif data.size == 3
      value = data[3][0..-2]
    elsif data.size > 4 && data[4] == '//'
      value = data[3][0..-2]
    else
      value = data[3..-1].join(' ')[0..-2]
    end

    values = {
      'deprecated' => flags.include?('deprecated') ? 'deprecated' : 'not deprecated',
      'visibility' => visibility,
      'name' => name,
      'type' => type
    }
    %w(transient final static volatile).each{|i| values[i] = flags.include?(i).to_s}
    values['value'] = value if value

    tag_start('field', values)
  end

  def read_method
    doc.scan(/(public|protected)([a-z\s]*)\s([a-zA-Z0-9\.<>\s,\[\]\?]+)\s([a-zA-Z0-9_]*)\(([^\)]*)\)(\sthrows[^;]+)?;$\s*/)
    visibility, modifiers, ret, name, params = doc[1], doc[2], doc[3], doc[4], doc[5]
    modifiers = modifiers.strip.split(' ')
    # ignore throws

    values = {
        'deprecated' => modifiers.include?('deprecated') ? 'deprecated' : 'not deprecated',
        'visibility' => visibility,
        'name' => name,
        'return' => ret,
    }
    %w(final synchronized native abstract static).each{|i| values[i] = modifiers.include?(i).to_s}

    tag_start('method', values)

    params.split(', ').each_with_index do |p, i|
      tag_start('parameter', {'name' => "arg#{i}", 'type' => p})
    end
  end

  def read_enum_constant
    visibility = doc.scan(/\w+/)
    doc.scan(/\s+/)
    name = doc.scan(/.*$\s*/)
  end
end

