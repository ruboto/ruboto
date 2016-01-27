require_relative 'test_helper'

# need JRuby jars for: Java::RubyDebugService.new.basicLoad(JRuby.runtime)
if RubotoTest::RUBOTO_PLATFORM == 'STANDALONE'

  class DebuggerTest < Minitest::Test

    DEBUGGER_GEMS = [
      [ 'columnize',       '~> 0.9.0' ],
      [ 'linecache',       '~> 1.3.1' ],
      [ 'ruby-debug-base', '~> 0.10.6' ],
      [ 'ruby-debug',      '~> 0.10.6' ],
    ]

    def setup
      generate_app bundle: DEBUGGER_GEMS
    end

    def teardown
      cleanup_app
    end

    def test_app_runs
      Dir.chdir APP_DIR do
        File.open('src/ruboto_test_app_activity.rb', 'w') do |file|
          file << <<EOF 
require 'ruboto/widget'
require 'ruboto/util/toast'
require 'ruboto/util/stack'

ruboto_import_widgets :Button, :LinearLayout, :TextView

require 'ruby-debug'

class RubotoTestAppActivity

  def onCreate(bundle)
    super

    set_title 'Domo arigato, Mr Ruboto!'

    # Debugger.wait_connection = true
    Debugger.start_remote         

    # Thread.start do
    #   debugger
    #   puts "onCreate: debugger session begin"
    #   set_title 'Degugging Mr Ruboto!'
    #   puts "onCreate: debugger session end"
    # end.join

    self.content_view = linear_layout :orientation => :vertical do
      @text_view = text_view :text => 'What hath Matz wrought?', :id => 42, 
        :layout => {:width => :match_parent},
        :gravity => :center, :text_size => 48.0
      button :text => 'M-x butterfly', 
        :layout => {:width => :match_parent},
        :id => 43, :on_click_listener => proc { butterfly }
    end
  end

  private

  def butterfly
    @text_view.text = 'What hath Matz wrought!'

    # Thread.start do
    #   debugger
    #   puts "butterfly: debugger session begin"
    #   @text_view.text = 'Butterfly debugged!'
    #   puts "butterfly: debugger session end"
    # end.join

    toast 'Flipped a bit via butterfly'
  end

end
EOF
        end
      end
      run_app_tests
    end

    if RUBY_ENGINE == 'jruby'
      def test_app_debugs
        # TODO: local JRuby for android builds on Travis CI
      end
    end

  end

end
