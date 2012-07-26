import android.util.Log

class SampleBroadcastReceiver
  # will get called whenever the BroadcastReceiver receives an intent (whenever onReceive is called)
  def on_receive(context, intent)
    Log.v "SampleBroadcastReceiver", 'Broadcast received!'
    Log.v "SampleBroadcastReceiver", intent.getExtras.to_s
    context.run_on_ui_thread do
      begin
        $activity.title = 'Broadcast received!'
      rescue Exception
        Log.e "Exception setting title: #{$!.message}\n#{$!.backtrace.join("\n")}"
      end
    end
    Log.v "SampleBroadcastReceiver", 'Broadcast processed OK!'
  rescue Exception
    Log.e "Exception processing broadcast: #{$!.message}\n#{$!.backtrace.join("\n")}"
  end
end
