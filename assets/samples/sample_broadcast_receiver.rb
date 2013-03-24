import android.util.Log

class SampleBroadcastReceiver
  # will get called whenever the BroadcastReceiver receives an intent (whenever onReceive is called)
  def onReceive(context, intent)
    Log.v 'SampleBroadcastReceiver', 'Broadcast received!'
    Log.v 'SampleBroadcastReceiver', intent.getExtras.to_s
  rescue Exception
    Log.e "Exception processing broadcast: #{$!.message}\n#{$!.backtrace.join("\n")}"
  end
end
