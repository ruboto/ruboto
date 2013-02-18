# TODO(uwe): Remove when we stop supporting psych with Ruby 1.8 mode
if RUBY_VERSION < '1.9'
  require 'jruby'
  require 'rbconfig'
  org.jruby.ext.psych.PsychLibrary.new.load(JRuby.runtime, false)
  $LOADED_FEATURES << 'psych.so'
  $LOAD_PATH << File.join(Config::CONFIG['libdir'], 'ruby/1.9')
end
# ODOT

require 'ruboto/util/stack'
with_large_stack {require 'psych'}

# TODO(uwe): Remove when we stop supporting psych with Ruby 1.8 mode
if RUBY_VERSION < '1.9'
  $LOAD_PATH.delete File.join(Config::CONFIG['libdir'], 'ruby/1.9')
end
# ODOT

Psych::Parser
Psych::Handler

require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

class PsychActivity
  def on_create(bundle)
    super
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')
    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER do
          @decoded_view = text_view :id        => 42, :text => with_large_stack { Psych.load('--- foo') },
                                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER

          # TODO(uwe): Simplify when we stop supporting Psych in Ruby 1.8 mode
          if RUBY_VERSION >= '1.9'
            @encoded_view = text_view :id        => 43, :text => with_large_stack { Psych.dump('foo') },
                                      :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          end
        end
  end
end
