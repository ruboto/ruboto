require File.expand_path('test_helper', File.dirname(__FILE__))

#fake package import
def android
  OpenStruct.new('util' => OpenStruct.new('Log' => nil))
end

class Log
  def self.v(*args)
    raise 'Log.v should be called with two arguments' if args.length != 2
  end

  def self.e(*args)
    raise 'Log.e should be called with two arguments' if args.length != 2
  end
end

class SampleBroadcastReceiverTest < Minitest::Test
  require 'assets/samples/sample_broadcast_receiver'

  def test_on_receive_calls_log_v
    context = {}
    intent = OpenStruct.new(:getExtras => '')
    SampleBroadcastReceiver.new.onReceive(context, intent)
  end

  def test_on_receive_calls_log_e
    SampleBroadcastReceiver.new.onReceive(nil, nil)
  end

end
