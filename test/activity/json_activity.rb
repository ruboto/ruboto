require 'ruboto/util/stack'
require 'json'
require 'ruboto/widget'

ruboto_import_widgets :LinearLayout, :TextView

# I/System.out( 1700): Starting JSON Parser Service
# D/dalvikvm( 1700): JIT code cache reset in 102 ms (1048444 bytes 1/0)
# F/libc    ( 1700): Fatal signal 11 (SIGSEGV) at 0x00000000 (code=1), thread 1709 (FinalizerDaemon)
# D/dalvikvm( 1700): GC_CONCURRENT freed 2352K, 9% free 28484K/30980K, paused 26ms+126ms, total 834ms
# D/dalvikvm( 1700): WAIT_FOR_CONCURRENT_GC blocked 673ms
# I/DEBUG   (   35): *** *** *** *** *** *** *** *** *** *** *** *** *** *** *** ***
# I/DEBUG   (   35): Build fingerprint: 'generic/sdk/generic:4.2.2/JB_MR1.1/576024:eng/test-keys'
# I/DEBUG   (   35): Revision: '0'
# I/DEBUG   (   35): pid: 1700, tid: 1709, name: UNKNOWN  >>> org.ruboto.test_app <<<
# I/DEBUG   (   35): signal 11 (SIGSEGV), code 1 (SEGV_MAPERR), fault addr 00000000

class JsonActivity
  def onCreate(bundle)
    super
    set_title File.basename(__FILE__).chomp('_activity.rb').split('_').map { |s| "#{s[0..0].upcase}#{s[1..-1]}" }.join(' ')
    self.content_view =
        linear_layout :orientation => LinearLayout::VERTICAL, :gravity => android.view.Gravity::CENTER do
          text_view :id => 42, :text => with_large_stack { JSON.load('["foo"]')[0] },
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          text_view :id => 43, :text => with_large_stack { JSON.dump(%w(foo)) },
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
          text_view :id => 44, :text => with_large_stack { 'foo'.to_json },
                    :text_size => 48.0, :gravity => android.view.Gravity::CENTER
        end
  end
end
