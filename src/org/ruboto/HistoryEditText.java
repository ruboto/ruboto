package org.ruboto;

import java.util.ArrayList;
import java.util.List;

import android.content.Context;
import android.os.Bundle;
import android.text.Selection;
import android.view.KeyEvent;
import android.view.inputmethod.EditorInfo;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.TextView;

/*********************************************************************************************
 * 
 * AutoCompleteTextView as IRB history
 * @author Jan Berkel
 * Modified from EditText to AutoCompleteTextView by Scott Moyer
 */
public class HistoryEditText extends AutoCompleteTextView implements
	TextView.OnEditorActionListener
{ 
	public interface LineListener {
		void onNewLine(String s);
	}     

	private List<String> history = new ArrayList<String>();
	private ArrayAdapter<String> adapter = null;
	private LineListener listener;

	public HistoryEditText(Context ctxt) {
		super(ctxt);
		initListeners();
	}

	public HistoryEditText(Context ctxt,  android.util.AttributeSet attrs) {
		super(ctxt, attrs);    
		initListeners();
		initAdapter();
		this.setThreshold(0);
	}

	public HistoryEditText(Context ctxt,  android.util.AttributeSet attrs, int defStyle) {
		super(ctxt, attrs, defStyle);
		initListeners();
		initAdapter();
		this.setThreshold(0);
	}

	private void initListeners() {
		setOnEditorActionListener(this);
	}

	private void initAdapter() {
		adapter = new ArrayAdapter<String>(getContext(), android.R.layout.simple_dropdown_item_1line, history);
	    this.setAdapter(adapter);
	}

	public void onSaveInstanceState(Bundle savedInstanceState) {
    	savedInstanceState.putStringArrayList("history", (ArrayList<String>)history);
    }
    
    public void onRestoreInstanceState(Bundle savedInstanceState) {
    	if (savedInstanceState.containsKey("history")) history = savedInstanceState.getStringArrayList("history");
    	initAdapter();
    }
    
    @Override
    public boolean performClick() {
    	if (history.size() > 0) showDropDown();
    	return super.performClick();
    }
    
    public String getHistoryString() {
    	StringBuilder string = new StringBuilder();
        for (String aHistory : history) {
            string.append(aHistory);
            string.append("\n");
        }
    	return string.toString();
    }
    
	public boolean onEditorAction(TextView arg0, int actionId, KeyEvent event) {
		if (actionId == EditorInfo.IME_NULL) {
			String line = getText().toString();
			if (line.length() == 0) return true;
			
			int i=0;
			for(; i < history.size(); i++) {
				if (history.get(i).equals(line)) {
					history.remove(i);
					adapter.remove(adapter.getItem(i));
					break;
				}
			}
			history.add(0, line);
			adapter.insert(line, 0);

			if (listener != null) {
				listener.onNewLine(line);
				return true;
			}
		}
		return false;
	}

	public void setLineListener(LineListener l) { this.listener = l; }

	public void setCursorPosition(int pos) {
		Selection.setSelection(getText(), pos);
	}
}
