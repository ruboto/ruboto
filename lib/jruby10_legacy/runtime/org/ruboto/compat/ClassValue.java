package org.ruboto.compat;

import java.util.Map;
import java.util.WeakHashMap;

/**
 * Stand-in for java.lang.ClassValue, which Android only has from API 34.
 * jruby-core is rewritten at build time to extend this class instead.
 */
public abstract class ClassValue<T> {
    private final Map<Class<?>, Object> values = new WeakHashMap<Class<?>, Object>();
    private static final Object NULL = new Object();

    protected ClassValue() {}

    protected abstract T computeValue(Class<?> type);

    @SuppressWarnings("unchecked")
    public T get(Class<?> type) {
        Object v;
        synchronized (values) {
            v = values.get(type);
        }
        if (v == null) {
            // Compute outside the lock: computeValue may consult this
            // ClassValue for other classes.
            T computed = computeValue(type);
            synchronized (values) {
                v = values.get(type);
                if (v == null) {
                    v = computed == null ? NULL : computed;
                    values.put(type, v);
                }
            }
        }
        return v == NULL ? null : (T) v;
    }

    public void remove(Class<?> type) {
        synchronized (values) {
            values.remove(type);
        }
    }
}
