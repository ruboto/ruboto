package org.ruboto;

import android.content.Context;
import android.graphics.Canvas;
import android.util.AttributeSet;
import android.view.View;

public class RubotoView extends View {
	public RubotoView(Context context) {
		super(context);
	}

	public RubotoView(Context context, AttributeSet attrs) {
		super(context, attrs);
	}

	public RubotoView(Context context, AttributeSet attrs, int defStyle) {
		super(context, attrs, defStyle);
	}
	
    @Override 
    protected void onDraw(Canvas canvas) {
    	((RubotoActivity) getContext()).onDraw(this, canvas);
    }
	
    @Override 
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
    	((RubotoActivity) getContext()).onSizeChanged(this, w, h, oldw, oldh);
    }
}
