package org.jruby.util;

import java.net.URL;
import java.net.URLClassLoader;
import java.security.ProtectionDomain;
import java.util.Set;
import java.util.concurrent.ConcurrentSkipListSet;

/**
 * Android (ART) replacement for JRuby's class-defining class loader.
 *
 * ART cannot define JVM bytecode at runtime, so defineClass always throws --
 * with the attempted class name in the message, which is far more useful
 * than ART's generic "can't load this type of class file".
 *
 * hasClass in the original checks for a ".class" resource on this loader's
 * own (empty) URL list, which can never see the invoker classes Ruboto
 * pregenerates into the application dex.  This version asks the parent
 * class loader chain instead, so pregenerated invokers are found and used.
 */
public class ClassDefiningJRubyClassLoader extends URLClassLoader implements ClassDefiningClassLoader {
    public static final ProtectionDomain DEFAULT_DOMAIN;

    static {
        ProtectionDomain domain = null;
        try {
            domain = JRubyClassLoader.class.getProtectionDomain();
        } catch (SecurityException se) {
            // just use null since we can't acquire protection domain
        }
        DEFAULT_DOMAIN = domain;
    }

    private final Set<String> definedClasses = new ConcurrentSkipListSet<>();

    public ClassDefiningJRubyClassLoader(ClassLoader parent) {
        super(new URL[0], parent);
    }

    public Class<?> defineClass(String name, byte[] bytes) {
        throw new UnsupportedOperationException(
                "Ruboto: runtime class generation is not possible on Android: " + name);
    }

    public Class<?> defineClass(String name, byte[] bytes, ProtectionDomain domain) {
        throw new UnsupportedOperationException(
                "Ruboto: runtime class generation is not possible on Android: " + name);
    }

    public boolean hasClass(String className) {
        if (hasDefinedClass(className)) return true;
        try {
            Class.forName(className, false, this);
            return true;
        } catch (ClassNotFoundException | LinkageError e) {
            return false;
        }
    }

    public boolean hasDefinedClass(String className) {
        return definedClasses.contains(className);
    }
}
