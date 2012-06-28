require 'ruboto/broadcast_receiver'

import android.util.Log

class SampleBroadcastReceiver
  include Ruboto::BroadcastReceiver

  # will get called whenever the BroadcastReceiver receives an intent (whenever onReceive is called)
  def on_receive(context, intent)
    Log.v "SampleBroadcastReceiver", 'Broadcast received!'
    Log.v "SampleBroadcastReceiver", intent.getExtras.to_s
    context.run_on_ui_thread{$activity.title = 'Broadcast received!'}
    Log.v "SampleBroadcastReceiver", 'Broadcast processed OK!'
  end
end
