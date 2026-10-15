package org.jruby.runtime.opto;

import java.util.List;

import org.jruby.RubyModule;

/**
 * Android (ART) replacement for JRuby's failover SwitchPoint invalidator.
 * See SwitchPointInvalidator for the token-identity approach.
 */
public class FailoverSwitchPointInvalidator implements Invalidator {
    private volatile Object token;

    public FailoverSwitchPointInvalidator(int maxFailures) {
    }

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
