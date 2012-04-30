require 'ruboto/broadcast_receiver'

import android.util.Log

RubotoBroadcastReceiver.new_with_callbacks do
  # will get called whenever the BroadcastReceiver receives an intent (whenever onReceive is called)
  def on_receive(context, intent)
    Log.v "MYAPP", intent.getExtras.to_s
  end
end
