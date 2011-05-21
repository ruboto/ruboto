package THE_PACKAGE;

public class InheritingActivity extends org.ruboto.RubotoActivity {
	public void onCreate(android.os.Bundle arg0) {
		try {
			setSplash(Class.forName("THE_PACKAGE.R$layout").getField("splash")
					.getInt(null));
		} catch (Exception e) {
		}

		setScriptName("start.rb");
		super.onCreate(arg0);
	}
}
