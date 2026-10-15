require 'ruboto/widget'
require 'ruboto/toast'

ruboto_import_widgets :Button, :EditText, :LinearLayout, :ScrollView, :TextView

# Collects whatever a snippet prints.
#
# This would be StringIO, except that `require 'stringio'` does not work on
# Android: the extension registers itself through a runtime-generated invoker
# class, and generating classes at runtime is exactly what Ruboto's JRuby
# cannot do there.  $stdout only has to quack like an IO, so a plain object
# with the handful of methods Kernel#puts and friends reach for is enough.
class WearIrbOutput
  def initialize
    @buffer = +''
  end

  attr_reader :buffer

  def write(*args)
    args.each { |a| @buffer << a.to_s }
    args.map { |a| a.to_s.bytesize }.sum
  end

  def <<(arg)
    @buffer << arg.to_s
    self
  end

  def print(*args)
    args.each { |a| @buffer << a.to_s }
    nil
  end

  def printf(fmt, *args)
    @buffer << format(fmt, *args)
    nil
  end

  def puts(*args)
    if args.empty?
      @buffer << "\n"
    else
      args.flatten.each do |a|
        text = a.nil? ? '' : a.to_s
        @buffer << text
        @buffer << "\n" unless text.end_with?("\n")
      end
    end
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

# The REPL evaluates inside one of these rather than at top level, so `self` is
# something harmless and `activity` reaches the running Activity:
#
#   >> activity.resources.display_metrics.widthPixels
#   => 456
#
# It lives at the top level rather than nested inside the Activity because the
# Activity class is a JRuby proxy for a Java class, and reopening one of those
# is not the place to be defining constants.
class WearIrbContext
  def initialize(activity)
    @activity = activity
  end

  attr_reader :activity

  # `binding` captures wherever it is called, so the REPL's binding has to be
  # made from inside the object it should evaluate against.
  def irb_binding
    binding
  end

  def to_s
    'main'
  end
end

# An IRB console for Wear OS.
#
# Type Ruby into the field at the bottom and press Run; the expression is
# evaluated and its value appended to the transcript above.  One binding is
# reused for the life of the activity, so `a = 1` and then `a + 1` works.
# The rotary crown scrolls the transcript.  `clear` empties it.
#
# Nothing is evaluated on the UI thread.  JRuby has to parse before it can run,
# and on a watch parsing alone can outlast the five seconds Android gives an
# input handler to return -- which does not produce a slow app, it produces an
# ANR and a killed process.  Every evaluation therefore happens on a background
# thread and only the finished text is posted back to the UI.
class WearIrbActivity
  VOICE_REQUEST = 4711

  # A transcript that grows forever eventually costs more to lay out than the
  # code being tested costs to run.
  MAX_ENTRIES = 100

  BANNER = <<~TEXT.freeze
    Ruboto IRB

    Ruby goes in the box below.
    Crown scrolls. "clear" wipes this.
    `activity` is this Activity.
  TEXT

  def onCreate(bundle)
    super
    @entries = [BANNER.strip]
    @busy = false
    @binding = WearIrbContext.new(self).irb_binding
    build_screen
    # Wear OS routes back/swipe-dismiss through OnBackInvokedCallback,
    # never the legacy onBackPressed, so register explicitly.
    @back_callback = proc { handle_back }
    on_back_invoked_dispatcher.register_on_back_invoked_callback(
      android.window.OnBackInvokedDispatcher::PRIORITY_DEFAULT, @back_callback)
  rescue Exception
    puts "Exception creating activity: #{$!}"
    puts $!.backtrace.join("\n")
  end

  # legacy path, kept for completeness
  def onBackPressed
    handle_back
  end

  # A half-typed expression is easy to fat-finger on a watch and tedious to
  # retype, so back clears the input first and only exits once it is empty.
  def handle_back
    if @input && !@input.text.to_s.empty?
      @input.text = ''
    else
      finish
    end
  rescue Exception
    finish
  end

  # Rotary crown -> scroll the transcript.
  def onGenericMotionEvent(event)
    if @scroll && event.action == android.view.MotionEvent::ACTION_SCROLL &&
       (event.source & android.view.InputDevice::SOURCE_ROTARY_ENCODER) != 0
      factor = android.view.ViewConfiguration.get(self).scaled_vertical_scroll_factor
      delta = -(event.get_axis_value(android.view.MotionEvent::AXIS_SCROLL) * factor)
      @scroll.smooth_scroll_by(0, delta.to_i)
      return true
    end
    super
  end

  def onActivityResult(request_code, result_code, data)
    return unless request_code == VOICE_REQUEST
    return unless result_code == android.app.Activity::RESULT_OK && data
    spoken = data.get_string_array_list_extra(android.speech.RecognizerIntent::EXTRA_RESULTS)
    return if spoken.nil? || spoken.size == 0
    @input.text = spoken.get(0).to_s
  rescue Exception
    puts "Exception handling speech result: #{$!}"
  end

  private

  # ---------- screen ----------

  def build_screen
    pad = side_pad
    self.content_view =
        linear_layout orientation: :vertical,
                      padding: [pad, top_pad, pad, bottom_pad] do
          @scroll =
              scroll_view layout: {width: :match_parent, height: 0, weight: 1.0} do
                @transcript = text_view text: '', text_size: 11.0,
                                        typeface: android.graphics.Typeface::MONOSPACE,
                                        layout: {width: :match_parent}
              end
          # Autocapitalisation and suggestions turn Ruby into something that
          # does not parse, so the IME is asked for neither.
          @input = edit_text hint: 'ruby',
                             text_size: 12.0,
                             single_line: true,
                             input_type: android.text.InputType::TYPE_CLASS_TEXT |
                                         android.text.InputType::TYPE_TEXT_FLAG_NO_SUGGESTIONS,
                             layout: {width: :match_parent}
          linear_layout orientation: :horizontal, gravity: :center,
                        layout: {width: :match_parent} do
            button text: 'Run', on_click_listener: proc { submit }
            button text: 'Say', on_click_listener: proc { start_voice_input }
          end
        end
    render
  end

  def render
    @transcript.text = @entries.join("\n")
    # Scrolling has to wait until the new text has been measured, hence post.
    @scroll.post(proc { @scroll.full_scroll(android.view.View::FOCUS_DOWN) })
  end

  def append(text)
    @entries << text
    @entries.shift while @entries.size > MAX_ENTRIES
    render
  end

  # ---------- the REPL ----------

  def submit
    return if @busy
    source = @input.text.to_s.strip
    return if source.empty?

    if source == 'clear'
      @input.text = ''
      @entries = []
      render
      return
    end

    @input.text = ''
    append(">> #{source}")
    append('...')
    @busy = true
    background do
      result = evaluate(source)
      on_ui do
        @busy = false
        @entries.pop # drop the '...' marker
        append(result)
      end
    end
  end

  # Runs on a background thread.  Returns the text to show; it never raises,
  # because a REPL that dies on a typo is not a REPL.
  def evaluate(source)
    collector = WearIrbOutput.new
    previous = $stdout
    # $stdout is process-wide, so anything else printing during these few
    # seconds lands in the transcript too.  Only one evaluation runs at a
    # time (see @busy), which keeps that to a curiosity rather than a bug.
    $stdout = collector
    begin
      value = eval(source, @binding, '(irb)')
      printed = collector.buffer
      printed += "\n" unless printed.empty? || printed.end_with?("\n")
      "#{printed}=> #{safe_inspect(value)}"
    ensure
      $stdout = previous
    end
  rescue Exception => e
    # SyntaxError is not a StandardError, so this deliberately catches
    # Exception rather than the usual narrower thing.
    "#{e.class}: #{e.message}"
  end

  def safe_inspect(value)
    value.inspect
  rescue Exception
    "(#{value.class}: inspect failed)"
  end

  # ---------- voice input ----------

  # Typing Ruby on a watch is miserable, so offer dictation as well.  It is
  # best-effort: speech recognisers punctuate prose, not code, so expect to
  # fix up the result before running it.
  def start_voice_input
    intent = android.content.Intent.new(android.speech.RecognizerIntent::ACTION_RECOGNIZE_SPEECH)
    intent.put_extra(android.speech.RecognizerIntent::EXTRA_LANGUAGE_MODEL,
                     android.speech.RecognizerIntent::LANGUAGE_MODEL_FREE_FORM)
    intent.put_extra(android.speech.RecognizerIntent::EXTRA_PROMPT, 'Dictate Ruby')
    start_activity_for_result(intent, VOICE_REQUEST)
  rescue Exception
    # No recogniser installed, or package visibility hides it from us.
    toast 'No speech recogniser available'
  end

  # ---------- background work ----------

  def background(&work)
    java.lang.Thread.new(proc do
      begin
        work.call
      rescue Exception
        message = $!.to_s
        puts "Exception in IRB thread: #{message}"
        on_ui do
          @busy = false
          append("(irb) #{message}")
        end
      end
    end).start
  end

  def on_ui(&work)
    run_on_ui_thread(proc { work.call })
  end

  # ---------- layout helpers ----------

  # Padding keeps content inside the visible circle on round screens.  A
  # console wants more of the glass than a book does, so these are tighter
  # than the reader sample's.
  # NB: widthPixels/heightPixels are Java fields, so no snake_case aliases
  def side_pad
    (resources.display_metrics.widthPixels * 0.09).round
  end

  def top_pad
    (resources.display_metrics.heightPixels * 0.06).round
  end

  def bottom_pad
    (resources.display_metrics.heightPixels * 0.08).round
  end
end
