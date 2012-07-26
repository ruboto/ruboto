package THE_PACKAGE;

import android.os.Bundle;

public class InheritingActivity extends org.ruboto.EntryPointActivity {
	public void onCreate(Bundle bundle) {
		setRubyClassName(getClass().getSimpleName());
	    super.onCreate(bundle);
	}
}
