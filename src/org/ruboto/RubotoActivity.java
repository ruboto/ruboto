/**********************************************************************************************
*
* RubotoActivity.java is generated from RubotoClass.java.erb. Any changes needed in should be 
* made within the erb template or they will be lost.
*
*/

package org.ruboto;

import java.io.IOException;
import android.app.Activity;
import android.app.ProgressDialog;
import android.os.Handler;
import android.os.Bundle;

import org.jruby.Ruby;
import org.jruby.javasupport.util.RuntimeHelpers;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.javasupport.JavaUtil;
import org.jruby.exceptions.RaiseException;

public class RubotoActivity extends Activity
    implements
        android.hardware.SensorEventListener,
        java.lang.Runnable,
        android.view.View.OnClickListener,
        android.view.View.OnFocusChangeListener,
        android.view.View.OnLongClickListener,
        android.view.View.OnTouchListener,
        android.view.View.OnKeyListener,
        android.widget.AdapterView.OnItemSelectedListener,
        android.widget.AdapterView.OnItemLongClickListener,
        android.widget.AdapterView.OnItemClickListener,
        android.view.ViewGroup.OnHierarchyChangeListener,
        android.widget.TabHost.TabContentFactory,
        android.widget.TabHost.OnTabChangeListener,
        android.widget.TextView.OnEditorActionListener,
        android.widget.DatePicker.OnDateChangedListener,
        android.widget.TimePicker.OnTimeChangedListener,
        android.app.DatePickerDialog.OnDateSetListener,
        android.app.TimePickerDialog.OnTimeSetListener,
        android.content.DialogInterface.OnKeyListener,
        android.content.DialogInterface.OnMultiChoiceClickListener,
        android.content.DialogInterface.OnClickListener,
        android.content.DialogInterface.OnShowListener,
        android.content.DialogInterface.OnDismissListener,
        android.content.DialogInterface.OnCancelListener
{
    public static final int CB_ACTIVITY_RESULT = 0;
    public static final int CB_APPLY_THEME_RESOURCE = 1;
    public static final int CB_ATTACHED_TO_WINDOW = 2;
    public static final int CB_BACK_PRESSED = 3;
    public static final int CB_CHILD_TITLE_CHANGED = 4;
    public static final int CB_CONFIGURATION_CHANGED = 5;
    public static final int CB_CONTENT_CHANGED = 6;
    public static final int CB_CREATE_CONTEXT_MENU = 7;
    public static final int CB_CONTEXT_MENU_CLOSED = 8;
    public static final int CB_CREATE_DESCRIPTION = 9;
    public static final int CB_CREATE_DIALOG = 10;
    public static final int CB_CREATE_OPTIONS_MENU = 11;
    public static final int CB_CREATE_PANEL_MENU = 12;
    public static final int CB_CREATE_PANEL_VIEW = 13;
    public static final int CB_CREATE_THUMBNAIL = 14;
    public static final int CB_CREATE_VIEW = 15;
    public static final int CB_DESTROY = 16;
    public static final int CB_DETACHED_FROM_WINDOW = 17;
    public static final int CB_KEY_DOWN = 18;
    public static final int CB_KEY_LONG_PRESS = 19;
    public static final int CB_KEY_MULTIPLE = 20;
    public static final int CB_KEY_UP = 21;
    public static final int CB_LOW_MEMORY = 22;
    public static final int CB_MENU_OPENED = 23;
    public static final int CB_NEW_INTENT = 24;
    public static final int CB_OPTIONS_ITEM_SELECTED = 25;
    public static final int CB_OPTIONS_MENU_CLOSED = 26;
    public static final int CB_PANEL_CLOSED = 27;
    public static final int CB_PAUSE = 28;
    public static final int CB_POST_CREATE = 29;
    public static final int CB_POST_RESUME = 30;
    public static final int CB_PREPARE_DIALOG = 31;
    public static final int CB_PREPARE_OPTIONS_MENU = 32;
    public static final int CB_PREPARE_PANEL = 33;
    public static final int CB_RESTART = 34;
    public static final int CB_RESTORE_INSTANCE_STATE = 35;
    public static final int CB_RESUME = 36;
    public static final int CB_RETAIN_NON_CONFIGURATION_INSTANCE = 37;
    public static final int CB_SAVE_INSTANCE_STATE = 38;
    public static final int CB_SEARCH_REQUESTED = 39;
    public static final int CB_START = 40;
    public static final int CB_STOP = 41;
    public static final int CB_TITLE_CHANGED = 42;
    public static final int CB_TOUCH_EVENT = 43;
    public static final int CB_TRACKBALL_EVENT = 44;
    public static final int CB_USER_INTERACTION = 45;
    public static final int CB_USER_LEAVE_HINT = 46;
    public static final int CB_WINDOW_ATTRIBUTES_CHANGED = 47;
    public static final int CB_WINDOW_FOCUS_CHANGED = 48;
    public static final int CB_ACCURACY_CHANGED = 49;
    public static final int CB_SENSOR_CHANGED = 50;
    public static final int CB_RUN = 51;
    public static final int CB_CLICK = 52;
    public static final int CB_FOCUS_CHANGE = 53;
    public static final int CB_LONG_CLICK = 54;
    public static final int CB_TOUCH = 55;
    public static final int CB_KEY = 56;
    public static final int CB_ITEM_SELECTED = 57;
    public static final int CB_NOTHING_SELECTED = 58;
    public static final int CB_ITEM_LONG_CLICK = 59;
    public static final int CB_ITEM_CLICK = 60;
    public static final int CB_CHILD_VIEW_ADDED = 61;
    public static final int CB_CHILD_VIEW_REMOVED = 62;
    public static final int CB_CREATE_TAB_CONTENT = 63;
    public static final int CB_TAB_CHANGED = 64;
    public static final int CB_EDITOR_ACTION = 65;
    public static final int CB_DATE_CHANGED = 66;
    public static final int CB_TIME_CHANGED = 67;
    public static final int CB_DATE_SET = 68;
    public static final int CB_TIME_SET = 69;
    public static final int CB_DIALOG_KEY = 70;
    public static final int CB_DIALOG_MULTI_CHOICE_CLICK = 71;
    public static final int CB_DIALOG_CLICK = 72;
    public static final int CB_SHOW = 73;
    public static final int CB_DISMISS = 74;
    public static final int CB_CANCEL = 75;
    public static final int CB_DRAW = 76;
    public static final int CB_SIZE_CHANGED = 77;
	public static final int CB_LAST = 78;
	
	private boolean[] callbackOptions = new boolean [CB_LAST];
    
	private String remoteVariable = "";
	private ProgressDialog loadingDialog; 
    private final Handler loadingHandler = new Handler();
    private IRubyObject __this__;
    private Ruby __ruby__;

	public RubotoActivity setRemoteVariable(String var) {
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
	public void onCreate(Bundle savedState) {
		super.onCreate(savedState);

		if (Script.getRuby() == null){
                    Script.configDir(IRB.SDCARD_SCRIPTS_DIR, getFilesDir().getAbsolutePath() + "/scripts");
                    Script.setUpJRuby(null);
                    Script.defineGlobalVariable("$activity", this);
                    try {
                        new Script("start.rb").execute();
                    }
                    catch(IOException e){
                        ProgressDialog.show(this, "Script failed", "Something bad happened", true, false);
                    }
		} else {
                    Script.defineGlobalVariable("$hello", this);
                    setRemoteVariable("$hello");
                    Script.execute("start.rb");
                    Script.defineGlobalVariable("$bundle", savedState);
                    Script.execute(remoteVariable + "on_create($bundle)");
//            RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create", JavaUtil.convertJavaToRuby(__ruby__, savedState));
		}
	}
	


	/*********************************************************************************
	 *
	 * Ruby Generated Callback Methods
	 */
	
	/*
	 * android.app.Activity
	 */

	public void onActivityResult(int arg0, int arg1, android.content.Intent arg2) {
		if (callbackOptions[CB_ACTIVITY_RESULT]) {
			super.onActivityResult(arg0, arg1, arg2);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_activity_result", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onActivityResult(arg0, arg1, arg2);
		}
	}
	
	public void onApplyThemeResource(android.content.res.Resources.Theme arg0, int arg1, boolean arg2) {
		if (callbackOptions[CB_APPLY_THEME_RESOURCE]) {
			super.onApplyThemeResource(arg0, arg1, arg2);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_apply_theme_resource", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onApplyThemeResource(arg0, arg1, arg2);
		}
	}
	
	public void onAttachedToWindow() {
		if (callbackOptions[CB_ATTACHED_TO_WINDOW]) {
			super.onAttachedToWindow();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_attached_to_window");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onAttachedToWindow();
		}
	}
	
	public void onBackPressed() {
		if (callbackOptions[CB_BACK_PRESSED]) {
			super.onBackPressed();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_back_pressed");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onBackPressed();
		}
	}
	
	public void onChildTitleChanged(android.app.Activity arg0, java.lang.CharSequence arg1) {
		if (callbackOptions[CB_CHILD_TITLE_CHANGED]) {
			super.onChildTitleChanged(arg0, arg1);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_child_title_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onChildTitleChanged(arg0, arg1);
		}
	}
	
	public void onConfigurationChanged(android.content.res.Configuration arg0) {
		if (callbackOptions[CB_CONFIGURATION_CHANGED]) {
			super.onConfigurationChanged(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_configuration_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onConfigurationChanged(arg0);
		}
	}
	
	public void onContentChanged() {
		if (callbackOptions[CB_CONTENT_CHANGED]) {
			super.onContentChanged();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_content_changed");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onContentChanged();
		}
	}
	
	public boolean onContextItemSelected(android.view.MenuItem arg0) {
		if (callbackOptions[CB_CREATE_CONTEXT_MENU]) {
			super.onContextItemSelected(arg0);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_context_item_selected", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onContextItemSelected(arg0);
		}
	}
	
	public void onContextMenuClosed(android.view.Menu arg0) {
		if (callbackOptions[CB_CONTEXT_MENU_CLOSED]) {
			super.onContextMenuClosed(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_context_menu_closed", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onContextMenuClosed(arg0);
		}
	}
	
	public void onCreateContextMenu(android.view.ContextMenu arg0, android.view.View arg1, android.view.ContextMenu.ContextMenuInfo arg2) {
		if (callbackOptions[CB_CREATE_CONTEXT_MENU]) {
			super.onCreateContextMenu(arg0, arg1, arg2);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create_context_menu", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onCreateContextMenu(arg0, arg1, arg2);
		}
	}
	
	public java.lang.CharSequence onCreateDescription() {
		if (callbackOptions[CB_CREATE_DESCRIPTION]) {
			super.onCreateDescription();
            try {
            	return (java.lang.CharSequence)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create_description").toJava(java.lang.CharSequence.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return null;
            }
		} else {
			return super.onCreateDescription();
		}
	}
	
	public android.app.Dialog onCreateDialog(int arg0, android.os.Bundle arg1) {
		if (callbackOptions[CB_CREATE_DIALOG]) {
			super.onCreateDialog(arg0, arg1);
            try {
            	return (android.app.Dialog)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create_dialog", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(android.app.Dialog.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return null;
            }
		} else {
			return super.onCreateDialog(arg0, arg1);
		}
	}
	
	public boolean onCreateOptionsMenu(android.view.Menu arg0) {
		if (callbackOptions[CB_CREATE_OPTIONS_MENU]) {
			super.onCreateOptionsMenu(arg0);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create_options_menu", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onCreateOptionsMenu(arg0);
		}
	}
	
	public boolean onCreatePanelMenu(int arg0, android.view.Menu arg1) {
		if (callbackOptions[CB_CREATE_PANEL_MENU]) {
			super.onCreatePanelMenu(arg0, arg1);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create_panel_menu", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onCreatePanelMenu(arg0, arg1);
		}
	}
	
	public android.view.View onCreatePanelView(int arg0) {
		if (callbackOptions[CB_CREATE_PANEL_VIEW]) {
			super.onCreatePanelView(arg0);
            try {
            	return (android.view.View)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create_panel_view", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(android.view.View.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return null;
            }
		} else {
			return super.onCreatePanelView(arg0);
		}
	}
	
	public boolean onCreateThumbnail(android.graphics.Bitmap arg0, android.graphics.Canvas arg1) {
		if (callbackOptions[CB_CREATE_THUMBNAIL]) {
			super.onCreateThumbnail(arg0, arg1);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create_thumbnail", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onCreateThumbnail(arg0, arg1);
		}
	}
	
	public android.view.View onCreateView(java.lang.String arg0, android.content.Context arg1, android.util.AttributeSet arg2) {
		if (callbackOptions[CB_CREATE_VIEW]) {
			super.onCreateView(arg0, arg1, arg2);
            try {
            	return (android.view.View)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_create_view", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2)).toJava(android.view.View.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return null;
            }
		} else {
			return super.onCreateView(arg0, arg1, arg2);
		}
	}
	
	public void onDestroy() {
		if (callbackOptions[CB_DESTROY]) {
			super.onDestroy();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_destroy");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onDestroy();
		}
	}
	
	public void onDetachedFromWindow() {
		if (callbackOptions[CB_DETACHED_FROM_WINDOW]) {
			super.onDetachedFromWindow();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_detached_from_window");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onDetachedFromWindow();
		}
	}
	
	public boolean onKeyDown(int arg0, android.view.KeyEvent arg1) {
		if (callbackOptions[CB_KEY_DOWN]) {
			super.onKeyDown(arg0, arg1);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_key_down", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onKeyDown(arg0, arg1);
		}
	}
	
	public boolean onKeyLongPress(int arg0, android.view.KeyEvent arg1) {
		if (callbackOptions[CB_KEY_LONG_PRESS]) {
			super.onKeyLongPress(arg0, arg1);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_key_long_press", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onKeyLongPress(arg0, arg1);
		}
	}
	
	public boolean onKeyMultiple(int arg0, int arg1, android.view.KeyEvent arg2) {
		if (callbackOptions[CB_KEY_MULTIPLE]) {
			super.onKeyMultiple(arg0, arg1, arg2);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_key_multiple", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onKeyMultiple(arg0, arg1, arg2);
		}
	}
	
	public boolean onKeyUp(int arg0, android.view.KeyEvent arg1) {
		if (callbackOptions[CB_KEY_UP]) {
			super.onKeyUp(arg0, arg1);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_key_up", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onKeyUp(arg0, arg1);
		}
	}
	
	public void onLowMemory() {
		if (callbackOptions[CB_LOW_MEMORY]) {
			super.onLowMemory();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_low_memory");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onLowMemory();
		}
	}
	
	public boolean onMenuItemSelected(int arg0, android.view.MenuItem arg1) {
		if (callbackOptions[CB_CREATE_OPTIONS_MENU]) {
			super.onMenuItemSelected(arg0, arg1);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_menu_item_selected", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onMenuItemSelected(arg0, arg1);
		}
	}
	
	public boolean onMenuOpened(int arg0, android.view.Menu arg1) {
		if (callbackOptions[CB_MENU_OPENED]) {
			super.onMenuOpened(arg0, arg1);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_menu_opened", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onMenuOpened(arg0, arg1);
		}
	}
	
	public void onNewIntent(android.content.Intent arg0) {
		if (callbackOptions[CB_NEW_INTENT]) {
			super.onNewIntent(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_new_intent", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onNewIntent(arg0);
		}
	}
	
	public boolean onOptionsItemSelected(android.view.MenuItem arg0) {
		if (callbackOptions[CB_OPTIONS_ITEM_SELECTED]) {
			super.onOptionsItemSelected(arg0);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_options_item_selected", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onOptionsItemSelected(arg0);
		}
	}
	
	public void onOptionsMenuClosed(android.view.Menu arg0) {
		if (callbackOptions[CB_OPTIONS_MENU_CLOSED]) {
			super.onOptionsMenuClosed(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_options_menu_closed", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onOptionsMenuClosed(arg0);
		}
	}
	
	public void onPanelClosed(int arg0, android.view.Menu arg1) {
		if (callbackOptions[CB_PANEL_CLOSED]) {
			super.onPanelClosed(arg0, arg1);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_panel_closed", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onPanelClosed(arg0, arg1);
		}
	}
	
	public void onPause() {
		if (callbackOptions[CB_PAUSE]) {
			super.onPause();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_pause");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onPause();
		}
	}
	
	public void onPostCreate(android.os.Bundle arg0) {
		if (callbackOptions[CB_POST_CREATE]) {
			super.onPostCreate(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_post_create", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onPostCreate(arg0);
		}
	}
	
	public void onPostResume() {
		if (callbackOptions[CB_POST_RESUME]) {
			super.onPostResume();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_post_resume");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onPostResume();
		}
	}
	
	public void onPrepareDialog(int arg0, android.app.Dialog arg1, android.os.Bundle arg2) {
		if (callbackOptions[CB_PREPARE_DIALOG]) {
			super.onPrepareDialog(arg0, arg1, arg2);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_prepare_dialog", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onPrepareDialog(arg0, arg1, arg2);
		}
	}
	
	public boolean onPrepareOptionsMenu(android.view.Menu arg0) {
		if (callbackOptions[CB_PREPARE_OPTIONS_MENU]) {
			super.onPrepareOptionsMenu(arg0);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_prepare_options_menu", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onPrepareOptionsMenu(arg0);
		}
	}
	
	public boolean onPreparePanel(int arg0, android.view.View arg1, android.view.Menu arg2) {
		if (callbackOptions[CB_PREPARE_PANEL]) {
			super.onPreparePanel(arg0, arg1, arg2);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_prepare_panel", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onPreparePanel(arg0, arg1, arg2);
		}
	}
	
	public void onRestart() {
		if (callbackOptions[CB_RESTART]) {
			super.onRestart();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_restart");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onRestart();
		}
	}
	
	public void onRestoreInstanceState(android.os.Bundle arg0) {
		if (callbackOptions[CB_RESTORE_INSTANCE_STATE]) {
			super.onRestoreInstanceState(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_restore_instance_state", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onRestoreInstanceState(arg0);
		}
	}
	
	public void onResume() {
		if (callbackOptions[CB_RESUME]) {
			super.onResume();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_resume");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onResume();
		}
	}
	
	public java.lang.Object onRetainNonConfigurationInstance() {
		if (callbackOptions[CB_RETAIN_NON_CONFIGURATION_INSTANCE]) {
			super.onRetainNonConfigurationInstance();
            try {
            	return (java.lang.Object)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_retain_non_configuration_instance").toJava(java.lang.Object.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return null;
            }
		} else {
			return super.onRetainNonConfigurationInstance();
		}
	}
	
	public void onSaveInstanceState(android.os.Bundle arg0) {
		if (callbackOptions[CB_SAVE_INSTANCE_STATE]) {
			super.onSaveInstanceState(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_save_instance_state", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onSaveInstanceState(arg0);
		}
	}
	
	public boolean onSearchRequested() {
		if (callbackOptions[CB_SEARCH_REQUESTED]) {
			super.onSearchRequested();
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_search_requested").toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onSearchRequested();
		}
	}
	
	public void onStart() {
		if (callbackOptions[CB_START]) {
			super.onStart();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_start");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onStart();
		}
	}
	
	public void onStop() {
		if (callbackOptions[CB_STOP]) {
			super.onStop();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_stop");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onStop();
		}
	}
	
	public void onTitleChanged(java.lang.CharSequence arg0, int arg1) {
		if (callbackOptions[CB_TITLE_CHANGED]) {
			super.onTitleChanged(arg0, arg1);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_title_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onTitleChanged(arg0, arg1);
		}
	}
	
	public boolean onTouchEvent(android.view.MotionEvent arg0) {
		if (callbackOptions[CB_TOUCH_EVENT]) {
			super.onTouchEvent(arg0);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_touch_event", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onTouchEvent(arg0);
		}
	}
	
	public boolean onTrackballEvent(android.view.MotionEvent arg0) {
		if (callbackOptions[CB_TRACKBALL_EVENT]) {
			super.onTrackballEvent(arg0);
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_trackball_event", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
			return super.onTrackballEvent(arg0);
		}
	}
	
	public void onUserInteraction() {
		if (callbackOptions[CB_USER_INTERACTION]) {
			super.onUserInteraction();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_user_interaction");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onUserInteraction();
		}
	}
	
	public void onUserLeaveHint() {
		if (callbackOptions[CB_USER_LEAVE_HINT]) {
			super.onUserLeaveHint();
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_user_leave_hint");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onUserLeaveHint();
		}
	}
	
	public void onWindowAttributesChanged(android.view.WindowManager.LayoutParams arg0) {
		if (callbackOptions[CB_WINDOW_ATTRIBUTES_CHANGED]) {
			super.onWindowAttributesChanged(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_window_attributes_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onWindowAttributesChanged(arg0);
		}
	}
	
	public void onWindowFocusChanged(boolean arg0) {
		if (callbackOptions[CB_WINDOW_FOCUS_CHANGED]) {
			super.onWindowFocusChanged(arg0);
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_window_focus_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		} else {
			super.onWindowFocusChanged(arg0);
		}
	}
	
	/*
	 * android.hardware.SensorEventListener
	 */

	public void onAccuracyChanged(android.hardware.Sensor arg0, int arg1) {
		if (callbackOptions[CB_ACCURACY_CHANGED]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_accuracy_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	public void onSensorChanged(android.hardware.SensorEvent arg0) {
		if (callbackOptions[CB_SENSOR_CHANGED]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_sensor_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * java.lang.Runnable
	 */

	public void run() {
		if (callbackOptions[CB_RUN]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "run");
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.view.View$OnCreateContextMenuListener
	 */

	/*
	 * android.view.View$OnClickListener
	 */

	public void onClick(android.view.View arg0) {
		if (callbackOptions[CB_CLICK]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_click", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.view.View$OnFocusChangeListener
	 */

	public void onFocusChange(android.view.View arg0, boolean arg1) {
		if (callbackOptions[CB_FOCUS_CHANGE]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_focus_change", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.view.View$OnLongClickListener
	 */

	public boolean onLongClick(android.view.View arg0) {
		if (callbackOptions[CB_LONG_CLICK]) {
			
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_long_click", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
	        return false;
		}
	}
	
	/*
	 * android.view.View$OnTouchListener
	 */

	public boolean onTouch(android.view.View arg0, android.view.MotionEvent arg1) {
		if (callbackOptions[CB_TOUCH]) {
			
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_touch", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
	        return false;
		}
	}
	
	/*
	 * android.view.View$OnKeyListener
	 */

	public boolean onKey(android.view.View arg0, int arg1, android.view.KeyEvent arg2) {
		if (callbackOptions[CB_KEY]) {
			
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_key", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
	        return false;
		}
	}
	
	/*
	 * android.widget.AdapterView$OnItemSelectedListener
	 */

	public void onItemSelected(android.widget.AdapterView arg0, android.view.View arg1, int arg2, long arg3) {
		if (callbackOptions[CB_ITEM_SELECTED]) {
			
            try {
            	IRubyObject[] args = {JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2), JavaUtil.convertJavaToRuby(__ruby__, arg3)};
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_item_selected", args);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	public void onNothingSelected(android.widget.AdapterView arg0) {
		if (callbackOptions[CB_NOTHING_SELECTED]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_nothing_selected", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.widget.AdapterView$OnItemLongClickListener
	 */

	public boolean onItemLongClick(android.widget.AdapterView arg0, android.view.View arg1, int arg2, long arg3) {
		if (callbackOptions[CB_ITEM_LONG_CLICK]) {
			
            try {
            	IRubyObject[] args = {JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2), JavaUtil.convertJavaToRuby(__ruby__, arg3)};
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_item_long_click", args).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
	        return false;
		}
	}
	
	/*
	 * android.widget.AdapterView$OnItemClickListener
	 */

	public void onItemClick(android.widget.AdapterView arg0, android.view.View arg1, int arg2, long arg3) {
		if (callbackOptions[CB_ITEM_CLICK]) {
			
            try {
            	IRubyObject[] args = {JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2), JavaUtil.convertJavaToRuby(__ruby__, arg3)};
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_item_click", args);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.view.ViewGroup$OnHierarchyChangeListener
	 */

	public void onChildViewAdded(android.view.View arg0, android.view.View arg1) {
		if (callbackOptions[CB_CHILD_VIEW_ADDED]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_child_view_added", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	public void onChildViewRemoved(android.view.View arg0, android.view.View arg1) {
		if (callbackOptions[CB_CHILD_VIEW_REMOVED]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_child_view_removed", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.widget.TabHost$TabContentFactory
	 */

	public android.view.View createTabContent(java.lang.String arg0) {
		if (callbackOptions[CB_CREATE_TAB_CONTENT]) {
			
            try {
            	return (android.view.View)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "create_tab_content", JavaUtil.convertJavaToRuby(__ruby__, arg0)).toJava(android.view.View.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return null;
            }
		} else {
	        return null;
		}
	}
	
	/*
	 * android.widget.TabHost$OnTabChangeListener
	 */

	public void onTabChanged(java.lang.String arg0) {
		if (callbackOptions[CB_TAB_CHANGED]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_tab_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.widget.TextView$OnEditorActionListener
	 */

	public boolean onEditorAction(android.widget.TextView arg0, int arg1, android.view.KeyEvent arg2) {
		if (callbackOptions[CB_EDITOR_ACTION]) {
			
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_editor_action", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
	        return false;
		}
	}
	
	/*
	 * android.widget.DatePicker$OnDateChangedListener
	 */

	public void onDateChanged(android.widget.DatePicker arg0, int arg1, int arg2, int arg3) {
		if (callbackOptions[CB_DATE_CHANGED]) {
			
            try {
            	IRubyObject[] args = {JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2), JavaUtil.convertJavaToRuby(__ruby__, arg3)};
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_date_changed", args);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.widget.TimePicker$OnTimeChangedListener
	 */

	public void onTimeChanged(android.widget.TimePicker arg0, int arg1, int arg2) {
		if (callbackOptions[CB_TIME_CHANGED]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_time_changed", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.app.DatePickerDialog$OnDateSetListener
	 */

	public void onDateSet(android.widget.DatePicker arg0, int arg1, int arg2, int arg3) {
		if (callbackOptions[CB_DATE_SET]) {
			
            try {
            	IRubyObject[] args = {JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2), JavaUtil.convertJavaToRuby(__ruby__, arg3)};
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_date_set", args);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.app.TimePickerDialog$OnTimeSetListener
	 */

	public void onTimeSet(android.widget.TimePicker arg0, int arg1, int arg2) {
		if (callbackOptions[CB_TIME_SET]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_time_set", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.content.DialogInterface$OnKeyListener
	 */

	public boolean onKey(android.content.DialogInterface arg0, int arg1, android.view.KeyEvent arg2) {
		if (callbackOptions[CB_DIALOG_KEY]) {
			
            try {
            	return (Boolean)RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_dialog_key", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2)).toJava(boolean.class);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        return false;
            }
		} else {
	        return false;
		}
	}
	
	/*
	 * android.content.DialogInterface$OnMultiChoiceClickListener
	 */

	public void onClick(android.content.DialogInterface arg0, int arg1, boolean arg2) {
		if (callbackOptions[CB_DIALOG_MULTI_CHOICE_CLICK]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_dialog_multi_choice_click", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.content.DialogInterface$OnClickListener
	 */

	public void onClick(android.content.DialogInterface arg0, int arg1) {
		if (callbackOptions[CB_DIALOG_CLICK]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_dialog_click", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.content.DialogInterface$OnShowListener
	 */

	public void onShow(android.content.DialogInterface arg0) {
		if (callbackOptions[CB_SHOW]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_show", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.content.DialogInterface$OnDismissListener
	 */

	public void onDismiss(android.content.DialogInterface arg0) {
		if (callbackOptions[CB_DISMISS]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_dismiss", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * android.content.DialogInterface$OnCancelListener
	 */

	public void onCancel(android.content.DialogInterface arg0) {
		if (callbackOptions[CB_CANCEL]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_cancel", JavaUtil.convertJavaToRuby(__ruby__, arg0));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	/*
	 * none
	 */

	public void onDraw(android.view.View arg0, android.graphics.Canvas arg1) {
		if (callbackOptions[CB_DRAW]) {
			
            try {
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_draw", JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1));
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
	public void onSizeChanged(android.view.View arg0, int arg1, int arg2, int arg3, int arg4) {
		if (callbackOptions[CB_SIZE_CHANGED]) {
			
            try {
            	IRubyObject[] args = {JavaUtil.convertJavaToRuby(__ruby__, arg0), JavaUtil.convertJavaToRuby(__ruby__, arg1), JavaUtil.convertJavaToRuby(__ruby__, arg2), JavaUtil.convertJavaToRuby(__ruby__, arg3), JavaUtil.convertJavaToRuby(__ruby__, arg4)};
            	RuntimeHelpers.invoke(__ruby__.getCurrentContext(), __this__, "on_size_changed", args);
            } catch (RaiseException re) {
                re.printStackTrace(__ruby__.getErrorStream());
		        
            }
		}
	}
	
}
