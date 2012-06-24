package THE_PACKAGE;

public class InheritingService extends org.ruboto.RubotoService {
	public void onCreate() {
	    System.out.println("InheritingService.onCreate()");
		setScriptName("sample_service.rb");
		super.onCreate();
	}

}
