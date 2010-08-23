/**********************************************************************************************
*
* RubotoBroadcastReceiver.java is generated from RubotoClass.java.erb. Any changes needed in should be 
* made within the erb template or they will be lost.
*
*/

package org.ruboto;

import java.io.IOException;
import android.content.BroadcastReceiver;
import android.os.Handler;
import android.os.Bundle;

import org.jruby.Ruby;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.exceptions.RaiseException;

public abstract class RubotoBroadcastReceiver extends BroadcastReceiver
    
{
    public static final int CB_CHECK_SYNCHRONOUS_HINT = 0;
    public static final int CB_PEEK_SERVICE = 1;
	public static final int CB_LAST = 2;
	
	private boolean[] callbackOptions = new boolean [CB_LAST];
    
	private String remoteVariable = "";

    private final Handler loadingHandler = new Handler();
    private IRubyObject __this__;
    private Ruby __ruby__;
    private String scriptName;

	public RubotoBroadcastReceiver setRemoteVariable(String var) {
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
	public void onReceive(android.content.Context arg0, android.content.Intent arg1) {



		if (Script.getRuby() == null){
                    Script.setUpJRuby(null);
		}
                Script.defineGlobalVariable("$broadcast_receiver", this);


                __ruby__ = Script.getRuby();
                __this__ = JavaUtil.convertJavaToRuby(__ruby__, RubotoBroadcastReceiver.this);

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
	 * android.content.BroadcastReceiver
	 */

	public void checkSynchronousHint() {
		if (callbackOptions[CB_CHECK_SYNCHRONOUS_HINT]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "check_synchronous_hint");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                
            }
		}
	}
	
	public android.os.IBinder peekService(android.content.Context arg0, android.content.Intent arg1) {
		if (callbackOptions[CB_PEEK_SERVICE]) {
			
            try {
            	return (android.os.IBinder)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "peek_service", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(android.os.IBinder.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
                return null;
            }
		} else {
                return null;
		}
	}
	
}
