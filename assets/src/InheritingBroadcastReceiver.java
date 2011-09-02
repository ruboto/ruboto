package THE_PACKAGE;

public class InheritingBroadcastReceiver extends org.ruboto.RubotoBroadcastReceiver {

    public InheritingBroadcastReceiver() {
        if (Script.setUpJRuby(context)) {
		    super("start.rb");
        } else {
        	// FIXME(uwe): What to do if the Ruboto Core platform is missing?
        }
	}

}
