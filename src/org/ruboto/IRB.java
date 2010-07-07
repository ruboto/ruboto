package org.ruboto;


import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.PrintStream;
import java.util.List;

import org.ruboto.Script;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.os.Process;
import android.text.util.Linkify;
import android.util.Log;
import android.view.ContextMenu;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.ContextMenu.ContextMenuInfo;
import android.view.inputmethod.InputMethodManager;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.ScrollView;
import android.widget.TabHost;
import android.widget.TabWidget;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.AdapterView.AdapterContextMenuInfo;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.TabHost.OnTabChangeListener;

public class IRB extends Activity implements OnItemClickListener, OnTabChangeListener {
    public static final String TAG = "Ruboto-IRB";
    public static final String SDCARD_SCRIPTS_DIR = "/sdcard/jruby";
    
    private TabHost tabs;
    private TabWidget tabWidget;
    private final Handler handler = new Handler();

    /* IRB_Tab Elements */
    public static TextView currentIrbOutput;
    private TextView irbOutput;
    private HistoryEditText irbInput;

    /* Edit_Tab Elements */
    private EditText sourceEditor;
    private TextView fnameTextView;
    private Script currentScript;

    /* Script_Tab Elements */
    private ArrayAdapter<String> adapter;
    private List<String> scripts;

    /* Tab identifiers */
    private static final int IRB_TAB = 0;
    private static final int EDITOR_TAB = 1;
    private static final int SCRIPTS_TAB = 2;

    /* Menu option identifiers */
    private static final int SAVE_MENU = 1;
    private static final int RUN_MENU = 2;
    private static final int NEW_MENU = 3;
    private static final int HISTORY_MENU = 4;
    private static final int ABOUT_MENU = 5;
    private static final int RESCAN_MENU = 6;
    private static final int RELOAD_DEMOS = 7;
    private static final int CLEAR_IRB = 8;
    private static final int EDIT_IRB = 9;
    private static final int MAX_SCREEN = 10;

    /* Context menu option identifiers for script list */
    private static final int EDIT_MENU = 20;
    private static final int EXECUTE_MENU = 21;
    private static final int DELETE_MENU = 22;

    private static final String DEMO_SCRIPTS = "demo-scripts";
    
    /*********************************************************************************************
     *
     * Setup
     */

    @Override
    public void onCreate(Bundle savedInstanceState) {
    	super.onCreate(savedInstanceState);

        SharedPreferences prefs = getPreferences(Context.MODE_PRIVATE);
        if (prefs.getBoolean("HideTitle", false)) requestWindowFeature(Window.FEATURE_NO_TITLE);
    	if (prefs.getBoolean("Fullscreen", false)) getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);

    	setContentView(R.layout.main);

        tabs = (TabHost) findViewById(R.id.tabhost);
        tabs.setOnTabChangedListener(this);
        tabs.setup();
                
        tabWidget = (TabWidget) findViewById(android.R.id.tabs);
    	tabWidget.setVisibility(prefs.getBoolean("HideTabs", false) ? View.GONE : View.VISIBLE);

        irbSetUp();
        configScriptsDir();
        editorSetUp();
        scriptsListSetUp();
        setUpJRuby();
    }

    private void irbSetUp() {
        tabs.addTab(tabs.newTabSpec("irb")
                .setContent(R.id.tab1)
                .setIndicator(getString(R.string.IRB_Tab)));

        irbInput = (HistoryEditText) findViewById(R.id.irb_edittext);
        irbOutput = (TextView) findViewById(R.id.irb_textview);
        irbOutput.setMovementMethod(new android.text.method.ScrollingMovementMethod());
        currentIrbOutput = irbOutput;

        irbInput.setLineListener(new HistoryEditText.LineListener() {
            public void onNewLine(String rubyCode) {
                irbOutput.append(rubyCode + "\n");
                String inspected = Script.execute(rubyCode);
                irbOutput.append("=> " + inspected + "\n");
                irbOutput.append(">> ");
                irbInput.setText("");
            }
        });
    }

    private void editorSetUp() {
        tabs.addTab(tabs.newTabSpec("editor")
                .setContent(R.id.tab2)
                .setIndicator(getString(R.string.Editor_Tab)));

        sourceEditor = (EditText) findViewById(R.id.source_editor);
        fnameTextView = (TextView) findViewById(R.id.fname_textview);
        editScript(Script.UNTITLED_RB, false);
    }

    private void scriptsListSetUp() {
    	tabs.addTab(tabs.newTabSpec("scripts")
                .setContent(R.id.tab3)
                .setIndicator(getString(R.string.Scripts_Tab)));

        ListView scriptsList = (ListView) findViewById(R.id.scripts_listview);

        scripts = Script.list();
        adapter = new ArrayAdapter<String>(this, android.R.layout.simple_list_item_1, scripts);
        scriptsList.setAdapter(adapter);
        TextView emptyView = new TextView(this);
        emptyView.setText(R.string.No_scripts);
        scriptsList.setEmptyView(emptyView);
        scriptsList.setOnItemClickListener(this);
        registerForContextMenu(scriptsList);
    }

    /* Initializes jruby in its own thread */
    private void setUpJRuby() {
        if (!Script.initialized()) {
            irbOutput.append("Initializing JRuby...");
            new Thread("JRuby-init") {
                public void run() {
                    // try to avoid ANR's
                    Process.setThreadPriority(Process.THREAD_PRIORITY_BACKGROUND);
                    Script.setUpJRuby(new PrintStream(new OutputStream() {
                        @Override
                        public void write(int arg0) throws IOException {
                            IRB.appendToIRB(Character.toString((char) arg0));
                        }
                    }));
                    handler.post(notifyComplete);
                }
            }.start();
        } else {
            notifyComplete.run();
        }
    }

    /* Called when jruby finishes loading */
    protected final Runnable notifyComplete = new Runnable() {
        public void run() {
            Script.defineGlobalVariable("$activity", IRB.this);
            irbOutput.append("Done\n>>");
            autoLoadScript();
        }
    };

    /* Static method needed to get to the current irbOutput after the Activity reloads */
    public static void appendToIRB(String string) {
        currentIrbOutput.append(string);
    }

    /* Loads the script specified in the Intent (if supplied) */
    public void autoLoadScript() {
		if (getIntent().getData() != null) {
			Script script = Script.fromURL(getIntent().getData().toString());
			if (script != null) editScript(script, true);
		}
    }
    
    /*********************************************************************************************
     *
     * Saving and recalling state
     */

    @Override
    public void onSaveInstanceState(Bundle savedInstanceState) {
        super.onSaveInstanceState(savedInstanceState);
        savedInstanceState.putCharSequence("irbOutput", irbOutput.getText());
        irbInput.onSaveInstanceState(savedInstanceState);
        savedInstanceState.putInt("tab", tabs.getCurrentTab());
    }

    @Override
    public void onRestoreInstanceState(Bundle savedInstanceState) {
        super.onRestoreInstanceState(savedInstanceState);
        if (savedInstanceState.containsKey("irbOutput"))
            irbOutput.setText(savedInstanceState.getCharSequence("irbOutput"));
        irbInput.onRestoreInstanceState(savedInstanceState);
        if (savedInstanceState.containsKey("tab")) tabs.setCurrentTab(savedInstanceState.getInt("tab"));
    }
    
    /*********************************************************************************************
    *
    * TabHost Listener
    */

    public void onTabChanged (String tabId) {
    	if (tabId.equals("scripts") ) {
            ((InputMethodManager)getSystemService(Context.INPUT_METHOD_SERVICE))
            	.hideSoftInputFromWindow(tabs.getWindowToken(), 0);
            if (Script.scriptsDirChanged()) scanScripts();
    	}
    }

    /*********************************************************************************************
     *
     * Menu Setup
     */

    /* Set up context menus */
    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.add(0, SAVE_MENU, 0, R.string.Menu_save).setIcon(android.R.drawable.ic_menu_save);
        menu.add(0, RUN_MENU, 0, R.string.Menu_run).setIcon(R.drawable.ic_menu_play);
        menu.add(0, NEW_MENU, 0, R.string.Menu_new).setIcon(android.R.drawable.ic_menu_add);
        menu.add(0, HISTORY_MENU, 0, R.string.Menu_history).setIcon(android.R.drawable.ic_menu_recent_history);
        menu.add(0, ABOUT_MENU, 0, R.string.Menu_about).setIcon(android.R.drawable.ic_menu_info_details);
        menu.add(0, RESCAN_MENU, 0, R.string.Menu_rescan);
        menu.add(0, RELOAD_DEMOS, 0, R.string.Menu_reload);
        menu.add(0, CLEAR_IRB, 0, R.string.Menu_clear_irb);
        menu.add(0, EDIT_IRB, 0, R.string.Menu_edit_irb);
        menu.add(0, MAX_SCREEN, 0, R.string.Menu_max_screen);
        return true;
    }

    /* Called when a menu item clicked */
    @Override
    public boolean onMenuItemSelected(int featureId, MenuItem item) {
        SharedPreferences prefs = null;
        SharedPreferences.Editor prefsEditor = null;

        switch (item.getItemId()) {
            case SAVE_MENU:
                saveEditorScript();
                return true;
            case RUN_MENU:
                runEditorScript();
                return true;
            case NEW_MENU:
                editScript(Script.UNTITLED_RB, true);
                return true;
            case HISTORY_MENU:
                editScript(new Script(Script.UNTITLED_RB, irbInput.getHistoryString()), true);
                return true;
            case ABOUT_MENU:
            	aboutDialog();
                return true;
            case RESCAN_MENU:
                scanScripts();
                tabs.setCurrentTab(SCRIPTS_TAB);
                return true;
            case RELOAD_DEMOS:
                Toast.makeText(this, 
                		recopyDemoScripts(DEMO_SCRIPTS, Script.getDirFile()), 
                		Toast.LENGTH_SHORT).show();
                scanScripts();
                tabs.setCurrentTab(SCRIPTS_TAB);
                return true;
            case 8:
            	irbOutput.setText(">> ");
                tabs.setCurrentTab(IRB_TAB);
                return true;
            case 9:
                editScript(new Script(Script.UNTITLED_RB, irbOutput.getText().toString()), true);
                tabs.setCurrentTab(EDITOR_TAB);
                return true;
            case 10:
                prefs = getPreferences(Context.MODE_PRIVATE);
                prefsEditor = prefs.edit();

                tabWidget.setVisibility(tabWidget.getVisibility() == View.VISIBLE ? View.GONE : View.VISIBLE);
            	if (prefs.getBoolean("Fullscreen", false)) {
            		getWindow().clearFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
            	} else {
                    getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN);
            	}

                prefsEditor.putBoolean("HideTabs", tabWidget.getVisibility() == View.GONE);
                prefsEditor.putBoolean("Fullscreen", !prefs.getBoolean("Fullscreen", false));
                prefsEditor.putBoolean("HideTitle", !prefs.getBoolean("HideTitle", false));
                prefsEditor.commit();

        		displayDialog("Title Visibility Change", "Reorient the screen for this to take effect.");

        		return true;
        }

        return super.onMenuItemSelected(featureId, item);
    }

    /* Set up context menus for script list */
    @Override
    public void onCreateContextMenu(ContextMenu menu, View v, ContextMenuInfo menuInfo) {
        super.onCreateContextMenu(menu, v, menuInfo);
        menu.add(0, EDIT_MENU, 0, R.string.Menu_edit);
        menu.add(0, EXECUTE_MENU, 0, R.string.Menu_run);
        menu.add(0, DELETE_MENU, 0, R.string.Menu_delete);
    }

    /* Called when an entry in the Script List is long clicked */
    public boolean onContextItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case EDIT_MENU:
                editScript(scripts.get(((AdapterContextMenuInfo) item.getMenuInfo()).position), true);
                return true;
            case EXECUTE_MENU:
                executeScript(scripts.get(((AdapterContextMenuInfo) item.getMenuInfo()).position));
                return true;
            case DELETE_MENU:
                comfirmDelete(scripts.get(((AdapterContextMenuInfo) item.getMenuInfo()).position));
                return true;
            default:
                return false;
        }
    }

    /* Called when an entry in the Script List is clicked */
    public void onItemClick(AdapterView<?> av, View v, int pos, long id) {
        editScript(scripts.get(pos), true);
    }

    /************************************************************************************
     *
     * Script actions
     */

    /* Reload the list of scripts */
    private void scanScripts() {
        try {
            scripts = Script.list(scripts);
            adapter.notifyDataSetChanged();
        }
        catch (SecurityException se) {
            Toast.makeText(this, "Could not create " + Script.getDir(), Toast.LENGTH_SHORT);
        }
    }

    /* Run the script currently in the editor */
    private void runEditorScript() {
        try {
            irbOutput.append("[Running editor script (" + currentScript.getName() + ")]\n");
            String inspected = currentScript.setContents(sourceEditor.getText().toString()).execute();
            irbOutput.append("=> " + inspected + "\n>> ");
            tabs.setCurrentTab(IRB_TAB);
        }
        catch (IOException e) {
            Toast.makeText(this, "Could not execute script", Toast.LENGTH_SHORT).show();
        }
    }

    /* Save the script currently in the editor */
    private void saveEditorScript() {
        try {
            currentScript
                    .setName(fnameTextView.getText().toString())
                    .setContents(sourceEditor.getText().toString())
                    .save();
            scanScripts();
            Toast.makeText(this, "Saved " + currentScript.getName(), Toast.LENGTH_SHORT).show();
            tabs.setCurrentTab(SCRIPTS_TAB);
        }
        catch (IOException e) {
            Toast.makeText(this, "Could not write " + currentScript.getName(), Toast.LENGTH_SHORT).show();
        }
    }

    /* Load script into editor and switch to editor view */
    private void editScript(Script script, Boolean switchTab) {
        try {
            currentScript = script;
            fnameTextView.setText(script.getName());
            sourceEditor.setText(script.getContents());
            if (switchTab) tabs.setCurrentTab(EDITOR_TAB);
        } catch (IOException e) {
            Toast.makeText(this, "Could not open " + script.getName(), Toast.LENGTH_SHORT).show();
        }
    }

    private void editScript(String name, Boolean switchTab) {
        editScript(new Script(name), switchTab);
    }

    /* Execute the script and switch to IRB tab*/
    private void executeScript(String name) {
        try {
            irbOutput.append("[Running " + name + "]\n");
            irbOutput.append("=> " + (new Script(name).execute()) + "\n>> ");
            tabs.setCurrentTab(IRB_TAB);
        }
        catch (IOException e) {
            Toast.makeText(this, "Could not open " + name, Toast.LENGTH_SHORT).show();
        }
    }

    /* Delete script and reload scripts list */
    private void deleteScript(String fname) {
        if (new Script(fname).delete()) {
            Toast.makeText(this, fname + " deleted!", Toast.LENGTH_SHORT).show();
        } else {
            Toast.makeText(this, "Could not delete " + fname, Toast.LENGTH_SHORT).show();
        }
        scanScripts();
    }

    /************************************************************************************
    *
    * Creates a dialog to confirm script deletion
    */
    private void comfirmDelete(final String fname) {
      AlertDialog.Builder builder = new AlertDialog.Builder(this);
      builder.setMessage("Delete " + fname + "?")
             .setCancelable(false)
             .setPositiveButton(R.string.Delete_confirm, new DialogInterface.OnClickListener() {
                 public void onClick(DialogInterface dialog, int id) {
                   deleteScript(fname);
                 }
               })
              .setNegativeButton(R.string.Delete_cancel, new DialogInterface.OnClickListener() {
                 public void onClick(DialogInterface dialog, int id) {
                   dialog.cancel();
                 }
               });
       builder.create().show();
   }

   /************************************************************************************
   *
   * Dialogs
   */
    
    private void displayDialog(String title, Object messageOrView) {

        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setTitle(title);
        if (messageOrView instanceof String) {
        	builder.setMessage((String)messageOrView);
        } else {
            builder.setView((View)messageOrView);
        }
        builder.setPositiveButton(R.string.About_dismiss, new DialogInterface.OnClickListener() {
        	public void onClick(DialogInterface dialog, int id) {}
        });
        builder.create().show();
   	}

    private void aboutDialog() {
		ScrollView sv = new ScrollView(this);
		TextView tv = new TextView(this);
		tv.setPadding(5, 5, 5, 5);
		tv.setText(R.string.About_text);
		Linkify.addLinks(tv, Linkify.ALL);
		sv.addView(tv);

		displayDialog(getString(R.string.app_name) + " v " + getString(R.string.version_name), sv);
   	}

    /*********************************************************************************************
     *
     * Activity Results: Make activity result available to Ruby
     */

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        Script.defineGlobalVariable("$last_activity_result", new ActivityResult(requestCode, resultCode, data));
    }

    public static class ActivityResult {
        public int requestCode, resultCode;
        public Intent data;

        public ActivityResult(int req, int res, Intent dat) {
            requestCode = req;
            resultCode = res;
            data = dat;
        }
    }

    private void configScriptsDir() {
        if (Script.configDir(SDCARD_SCRIPTS_DIR, getFilesDir().getAbsolutePath() + "/scripts")) {
            // on first install init directory + copy sample scripts
            copyDemoScripts(DEMO_SCRIPTS, Script.getDirFile());                
        }
    }
        
    private void copyDemoScripts(String from, File to) {                        
        try {
            byte[] buffer = new byte[8192];        
            for (String f : getAssets().list(from)) {
                File dest = new File(to, f);
                
                if (dest.exists()) 
                    continue;
                
                Log.d(TAG, "copying file " + f);                    
                                
                InputStream is = getAssets().open(from+ "/" +f);                    
                OutputStream fos = new BufferedOutputStream(new FileOutputStream(dest));    

                int n;
                while ((n = is.read(buffer, 0, buffer.length)) != -1)
                    fos.write(buffer, 0, n);                
                
                is.close();
                fos.close();                
            }
        } catch (IOException iox) {
            Log.e(TAG, "error copying demo scripts", iox);     
        }
    }    

    private String recopyDemoScripts(String from, File to) {      
    	String rv = "Copied:";
        try {
            byte[] buffer = new byte[8192];        
            for (String f : getAssets().list(from)) {
                File dest = new File(to, f);
                
                if (dest.exists()) {
                    Log.d(TAG, "replacing file " + f);                    
                } else {
                    Log.d(TAG, "copying file " + f);                    
                }
                
                                
                InputStream is = getAssets().open(from+ "/" +f);                    
                OutputStream fos = new BufferedOutputStream(new FileOutputStream(dest));    

                int n;
                while ((n = is.read(buffer, 0, buffer.length)) != -1)
                    fos.write(buffer, 0, n);                
                
                is.close();
                fos.close();   
                rv += "\n" + f;
            }
        } catch (IOException iox) {
            Log.e(TAG, "error copying demo scripts", iox);
            rv = "Copy failed";
        }
        return rv;
    }    
}
