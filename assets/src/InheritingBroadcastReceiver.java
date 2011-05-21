package THE_PACKAGE;

public class InheritingBroadcastReceiver extends org.ruboto.RubotoBroadcastReceiver {
	public void onReceive(android.content.Context arg0,
			android.content.Intent arg1) {
		setScriptName("start.rb");
		super.onReceive(arg0, arg1);
	}

}
