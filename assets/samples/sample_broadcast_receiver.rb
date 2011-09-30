require 'ruboto/broadcast_receiver'

# will get called whenever the BroadcastReceiver receives an intent (whenever onReceive is called)
RubotoBroadcastReceiver.new_with_callbacks do
  def on_receive(context, intent)
    Log.v "MYAPP", intent.getExtras.to_s
  end
end

