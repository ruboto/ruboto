require 'ruboto.rb'

# despite the name, the when_launched block will get called whenever
# the BroadcastReceiver receives an intent (whenever onReceive is called)
$broadcast_receiver.handle_receive do |context, intent|
  Log.v "MYAPP", intent.getExtras.to_s
end
