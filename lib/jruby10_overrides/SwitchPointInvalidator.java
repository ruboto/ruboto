package org.jruby.runtime.opto;

import java.util.List;

import org.jruby.RubyModule;

/**
 * Android (ART) replacement for JRuby's SwitchPoint-based invalidator.
 * ART has no java.lang.invoke.SwitchPoint, so cache validity is tracked
 * with an identity token that is replaced on invalidation, which callers
 * observe through getData() just like the original SwitchPoint instance.
 */
public class SwitchPointInvalidator implements Invalidator {
    private volatile Object token;

    public synchronized void invalidate() {
        token = null;
    }

    public void invalidateAll(List<Invalidator> invalidators) {
        for (Invalidator invalidator : invalidators) {
            if (invalidator != this) invalidator.invalidate();
        }
        invalidate();
    }

    public synchronized Object getData() {
        return token != null ? token : (token = new Object());
    }

    public void addIfUsed(RubyModule.InvalidatorList invalidators) {
        if (token != null) invalidators.add(this);
    }
}
