/**********************************************************************************************
*
* RubotoService.java is generated from RubotoClass.java.erb. Any changes needed in should be 
* made within the erb template or they will be lost.
*
*/

package org.ruboto;

import java.io.IOException;
import android.app.Service;
import android.os.Handler;
import android.os.Bundle;

import org.jruby.Ruby;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.exceptions.RaiseException;

public abstract class RubotoService extends Service
    
{
    public static final int CB_LOW_MEMORY = 0;
    public static final int CB_DUMP = 1;
    public static final int CB_UNBIND = 2;
    public static final int CB_START_COMMAND = 3;
    public static final int CB_FINALIZE = 4;
    public static final int CB_START = 5;
    public static final int CB_DESTROY = 6;
    public static final int CB_REBIND = 7;
    public static final int CB_CONFIGURATION_CHANGED = 8;
    public static final int CB_BIND = 9;
	public static final int CB_LAST = 10;
	
	private boolean[] callbackOptions = new boolean [CB_LAST];
    
	private String remoteVariable = "";

    private final Handler loadingHandler = new Handler();
    private IRubyObject __this__;
    private Ruby __ruby__;
    private String scriptName;
    protected Object[] args;

	public RubotoService setRemoteVariable(String var) {
		remoteVariable = ((var == null) ? "" : (var + "."));
		return this;
	}
	
	/**********************************************************************************
	 *  
	 *  Callback management
	 */
	
	public void requestCallback(int id) {
		callbackOptions[id] = true;
	}
	
	public void removeCallback(int id) {
		callbackOptions[id] = false;
	}
	
	/* 
	 *  Activity Lifecycle: onCreate
	 */
	
	@Override
	public void onCreate() {

		super.onCreate();


		if (Script.getRuby() == null){
                    Script.setUpJRuby(null);
                    Script.defineGlobalVariable("$service", this);
		}

                __ruby__ = Script.getRuby();
                __this__ = JavaUtil.convertJavaToRuby(__ruby__, RubotoService.this);

                try {
                    new Script(scriptName).execute();
                }
                catch(IOException e){

                }
	}

        public void setScriptName(String name){
               scriptName = name;
        }
	


	/*********************************************************************************
	 *
	 * Ruby Generated Callback Methods
	 */
	
	/*
	 * android.app.Service
	 */

	public void onLowMemory() {
		if (callbackOptions[CB_LOW_MEMORY]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_low_memory");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                
            }
		}
	}
	
	public void dump(java.io.FileDescriptor arg0, java.io.PrintWriter arg1, java.lang.String[] arg2) {
		if (callbackOptions[CB_DUMP]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "dump", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                
            }
		}
	}
	
	public boolean onUnbind(android.content.Intent arg0) {
		if (callbackOptions[CB_UNBIND]) {
			
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_unbind", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                return false;
            }
		} else {
                return false;
		}
	}
	
	public int onStartCommand(android.content.Intent arg0, int arg1, int arg2) {
		if (callbackOptions[CB_START_COMMAND]) {
			
            try {
            	return (Integer)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_start_command", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2)).toJava(int.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                return 0;
            }
		} else {
                return 0;
		}
	}
	
	public void finalize() {
		if (callbackOptions[CB_FINALIZE]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "finalize");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                
            }
		}
	}
	
	public void onStart(android.content.Intent arg0, int arg1) {
		if (callbackOptions[CB_START]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_start", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                
            }
		}
	}
	
	public void onDestroy() {
		if (callbackOptions[CB_DESTROY]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_destroy");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                
            }
		}
	}
	
	public void onRebind(android.content.Intent arg0) {
		if (callbackOptions[CB_REBIND]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_rebind", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                
            }
		}
	}
	
	public void onConfigurationChanged(android.content.res.Configuration arg0) {
		if (callbackOptions[CB_CONFIGURATION_CHANGED]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_configuration_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                
            }
		}
	}
	
	public android.os.IBinder onBind(android.content.Intent arg0) {
		if (callbackOptions[CB_BIND]) {
			
            try {
            	return (android.os.IBinder)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_bind", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(android.os.IBinder.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                return null;
            }
		} else {
                return null;
		}
	}
	
}
