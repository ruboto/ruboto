package THE_PACKAGE;

public class InheritingService extends org.ruboto.RubotoService {
	public void onCreate() {
		getScriptInfo().setRubyClassName(getClass().getSimpleName());
		super.onCreate();
	}

}
