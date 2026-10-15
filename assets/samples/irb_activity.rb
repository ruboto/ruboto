require 'ruboto/widget'
require 'ruboto/toast'
require 'fileutils'

ruboto_import_widgets :Button, :EditText, :LinearLayout, :ScrollView, :TextView

# Stands in for StringIO while a line is being evaluated, so that anything the
# line prints can be shown in the console instead of vanishing into logcat.
#
# StringIO itself cannot be used: it is a Java extension registered through a
# runtime-generated invoker, and Ruboto disables runtime class generation on
# Android, so `require 'stringio'` raises LoadError.  Only the handful of
# methods $stdout is asked for are implemented here.
class IrbOutput
  def initialize
    @buffer = +''
  end

  attr_reader :buffer

  def write(*args)
    args.each { |arg| @buffer << arg.to_s }
    args.inject(0) { |total, arg| total + arg.to_s.bytesize }
  end

  def <<(text)
    @buffer << text.to_s
    self
  end

  def print(*args)
    args.each { |arg| @buffer << arg.to_s }
    nil
  end

  def puts(*args)
    return @buffer << "\n" if args.empty?
    args.flatten.each do |arg|
      text = arg.to_s
      @buffer << text
      @buffer << "\n" unless text.end_with?("\n")
    end
    nil
  end

  def printf(template, *args)
    @buffer << sprintf(template, *args)
    nil
  end

  def flush
    self
  end

  def sync
    true
  end

  def sync=(value)
    value
  end

  def tty?
    false
  end

  def isatty
    false
  end
end

# `self` inside the console.  Evaluating against a plain object rather than the
# Activity keeps the REPL clear of Ruboto's generated callback methods, while
# `activity` still hands over the whole Android API.  Top level rather than
# nested in the Activity, which is a JRuby proxy for a Java class.
class IrbConsole
  def initialize(activity)
    @activity = activity
  end

  attr_reader :activity

  def to_s
    'main'
  end

  def console_binding
    binding
  end
end

# An IRB console for Android.
#
# Type Ruby, get a value back.  The binding persists between lines, so `a = 1`
# then `a + 1` works, and anything the line prints is captured and shown.
#
# It also installs gems.  RubyGems itself is disabled on Android because it
# cannot scan gem specifications inside the APK's jar: URI, but a .gem file is
# only a tar holding a data.tar.gz, so `gem install rack` here downloads one,
# unpacks its lib directory into the app's private storage and puts it on
# $LOAD_PATH.  RubyGems is never involved.  Pure Ruby gems work; anything with
# a C extension does not, and no dependency resolution is attempted.
#
# Needs the INTERNET permission -- add this to the app's AndroidManifest.xml,
# above <application>:
#
#   <uses-permission android:name="android.permission.INTERNET"/>
class IrbActivity
  PROMPT = '>> '
  MAX_ENTRIES = 200
  GEM_SOURCE = 'https://rubygems.org'

  BANNER = <<~TEXT
    Ruby #{RUBY_VERSION} on Android.

    Type an expression and press Run.
    The binding is kept between lines, and `activity` is this Activity.

      gem install NAME [VERSION]   fetch a pure Ruby gem and add it to $LOAD_PATH
      gem list                     what is installed
      help                         this text
  TEXT

  def onCreate(bundle)
    super
    @entries = []
    @busy = false
    @binding = IrbConsole.new(self).console_binding
    restore_installed_gems
    build_view
    append(BANNER)
  rescue Exception
    puts "Exception creating activity: #{$!}"
    puts $!.backtrace.join("\n")
  end

  private

  # ---------- console ----------

  def submit
    source = @input.text.to_s
    return if source.strip.empty?
    return toast('Still working on the last one') if @busy

    @input.set_text('')
    append("#{PROMPT}#{source}")
    @busy = true
    # Off the UI thread, always.  Evaluating Ruby means parsing Ruby, and a
    # parse on the main thread can outlast the five seconds Android gives an
    # input handler to respond, which gets the app killed rather than merely
    # slowed down.  Installing a gem does network I/O and is worse.
    background do
      reply = dispatch(source)
      on_ui do
        @busy = false
        append(reply)
      end
    end
  end

  # The `gem` commands are handled here instead of by eval, because they are
  # the one thing plain Ruby cannot do in this environment.
  def dispatch(source)
    case source.strip
    when /\Agem\s+install\s+(\S+)(?:\s+(\S+))?\z/ then install_gem($1, $2)
    when /\Agem\s+list\z/ then list_gems
    when /\Ahelp\z/ then BANNER
    else evaluate(source)
    end
  rescue Exception
    "#{$!.class}: #{$!.message}"
  end

  # rescue Exception, not StandardError: SyntaxError is a ScriptError, and a
  # console that dies on a typo is not much of a console.
  def evaluate(source)
    printed = IrbOutput.new
    previous, $stdout = $stdout, printed
    begin
      value = eval(source, @binding, '(irb)')
      "#{printed.buffer}=> #{safe_inspect(value)}"
    ensure
      $stdout = previous
    end
  rescue Exception
    "#{$!.class}: #{$!.message}"
  end

  def safe_inspect(value)
    value.inspect
  rescue Exception
    "(#{value.class} raised #{$!.class} from inspect)"
  end

  # ---------- gems ----------

  def gems_dir
    dir = File.join(files_dir.absolute_path, 'gems')
    FileUtils.mkdir_p(dir)
    dir
  end

  def list_gems
    installed = Dir[File.join(gems_dir, '*')].select { |d| File.directory?(d) }
    installed.empty? ? '(no gems installed)' : installed.map { |d| File.basename(d) }.sort.join("\n")
  end

  # Gems installed in an earlier session are still on disk but not on the load
  # path of this fresh JRuby runtime, so put them back.
  def restore_installed_gems
    Dir[File.join(gems_dir, '*', 'lib')].sort.each { |lib| add_to_load_path(lib) }
  rescue Exception
    puts "Could not restore installed gems: #{$!}"
  end

  def install_gem(name, version = nil)
    version ||= latest_version(name)
    target = File.join(gems_dir, "#{name}-#{version}")
    if File.directory?(target)
      add_to_load_path(File.join(target, 'lib'))
      return "#{name} #{version} is already installed"
    end

    archive = http_get("#{GEM_SOURCE}/downloads/#{name}-#{version}.gem")
    data = nil
    each_tar_entry(archive) { |entry, bytes| data = bytes if entry == 'data.tar.gz' }
    raise "#{name}-#{version}.gem holds no data.tar.gz" unless data

    written = 0
    each_tar_entry(gunzip(data)) do |entry, bytes|
      next unless entry.start_with?('lib/')
      next if bytes.nil? || entry.end_with?('/')
      path = File.join(target, entry)
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, 'wb') { |f| f << bytes }
      written += 1
    end
    if written.zero?
      FileUtils.rm_rf(target)
      raise "#{name} #{version} ships no lib directory"
    end

    add_to_load_path(File.join(target, 'lib'))
    "installed #{name} #{version}, #{written} files\n" \
      "dependencies are not resolved -- if require fails, install them too"
  end

  def latest_version(name)
    json = http_get("#{GEM_SOURCE}/api/v1/versions/#{name}/latest.json")
    # Deliberately a regex and not JSON.parse: the response is two fields, and
    # the json library is one more thing that has to survive on Android.
    version = json[/"version"\s*:\s*"([^"]+)"/, 1]
    raise "no such gem: #{name}" if version.nil? || version.empty? || version == 'unknown'
    version
  end

  def add_to_load_path(lib)
    $LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
  end

  # ---------- fetching and unpacking ----------

  def http_get(url)
    connection = java.net.URL.new(url).open_connection
    connection.instance_follow_redirects = true
    connection.connect_timeout = 15_000
    connection.read_timeout = 60_000
    code = connection.response_code
    raise "HTTP #{code} for #{url}" unless code == 200
    read_stream(connection.input_stream)
  end

  def gunzip(bytes)
    read_stream(java.util.zip.GZIPInputStream.new(
                  java.io.ByteArrayInputStream.new(bytes.to_java_bytes)))
  end

  def read_stream(stream)
    out = java.io.ByteArrayOutputStream.new
    buffer = Java::byte[16_384].new
    while (n = stream.read(buffer)) != -1
      out.write(buffer, 0, n)
    end
    stream.close
    String.from_java_bytes(out.to_byte_array).force_encoding('BINARY')
  end

  # Just enough of the tar format for a .gem: one 512 byte header per entry
  # carrying the name and an octal size, then the payload padded out to the
  # next 512 byte boundary.  Two empty headers end the archive.
  def each_tar_entry(archive)
    offset = 0
    while offset + 512 <= archive.bytesize
      header = archive.byteslice(offset, 512)
      break if header.getbyte(0).zero?
      name = nul_terminated(header.byteslice(0, 100))
      prefix = nul_terminated(header.byteslice(345, 155))
      name = "#{prefix}/#{name}" unless prefix.empty?
      size = nul_terminated(header.byteslice(124, 12)).strip.to_i(8)
      yield name, archive.byteslice(offset + 512, size)
      offset += 512 + (size + 511) / 512 * 512
    end
  end

  def nul_terminated(field)
    field.sub(/\0.*\z/m, '')
  end

  # ---------- threads ----------

  def background(&work)
    java.lang.Thread.new(proc do
      begin
        work.call
      rescue Exception
        message = "#{$!.class}: #{$!.message}"
        on_ui { @busy = false; append(message) }
      end
    end).start
  end

  def on_ui(&work)
    run_on_ui_thread(proc { work.call })
  end

  # ---------- view ----------

  def build_view
    self.content_view =
        linear_layout orientation: :vertical do
          @scroll = scroll_view layout: {width: :match_parent, height: 0, weight: 1} do
            @output = text_view text: '', text_size: 13.0,
                                typeface: android.graphics.Typeface::MONOSPACE,
                                padding: [16, 16, 16, 16],
                                text_is_selectable: true,
                                layout: {width: :match_parent}
          end
          linear_layout orientation: :horizontal,
                        padding: [8, 0, 8, 8],
                        layout: {width: :match_parent} do
            # Go on the soft keyboard submits, so the Run button is there for
            # when you want it rather than because you have to reach for it.
            @input = edit_text hint: 'ruby, or: gem install humanize',
                               text_size: 14.0,
                               typeface: android.graphics.Typeface::MONOSPACE,
                               single_line: true,
                               ime_options: android.view.inputmethod.EditorInfo::IME_ACTION_GO,
                               on_editor_action_listener: proc { |*| submit; true },
                               input_type: android.text.InputType::TYPE_CLASS_TEXT |
                                           android.text.InputType::TYPE_TEXT_FLAG_NO_SUGGESTIONS,
                               layout: {width: 0, weight: 1}
            button text: 'Run', on_click_listener: proc { submit }
          end
        end
  end

  def append(text)
    @entries << text.to_s
    @entries.shift while @entries.size > MAX_ENTRIES
    @output.text = @entries.join("\n\n")
    @scroll.post(proc { @scroll.full_scroll(android.view.View::FOCUS_DOWN) })
  end
end
