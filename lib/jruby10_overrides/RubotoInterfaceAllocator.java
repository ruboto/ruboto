package org.jruby.java.proxies;

import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.runtime.ObjectAllocator;

/**
 * Ruboto: the allocator JavaInterfaceTemplate.initInterfaceImplMethods wraps
 * when jruby.interfaces.useProxy=true (always on Android).
 *
 * JRuby 10.1.2 reads clazz.getAllocator() there and wraps it in a lambda that
 * allocates, then calls __jcreate! to attach a java.lang.reflect.Proxy.  Two
 * values break that wrapper:
 *
 *  - null: Interface.impl { } creates its class with
 *    RubyClass.newClass(context, Object, null), whose constructor does not copy
 *    the superclass allocator -> NullPointerException in
 *    JavaInterfaceTemplate.lambda$initInterfaceImplMethods$1.
 *  - RubyObject.IVAR_INSPECTING_OBJECT_ALLOCATOR / REIFYING_OBJECT_ALLOCATOR
 *    (named classes, jruby.reify.variables=true by default): both re-read
 *    klass.getAllocator(), which is now the wrapper, and call it again ->
 *    StackOverflowError for "class Foo; include java.lang.Runnable; end".
 *
 * Both are replaced by the plain RubyObject allocator; instances of such
 * classes keep their instance variables in the variable table instead of
 * specialized fields.
 *
 * JRuby10AndroidPatcher retargets the getAllocator() call in
 * initInterfaceImplMethods to baseAllocator(RubyClass), which has the same
 * stack shape.
 */
public final class RubotoInterfaceAllocator {
    private RubotoInterfaceAllocator() {
    }

    public static ObjectAllocator baseAllocator(RubyClass clazz) {
        ObjectAllocator allocator = clazz.getAllocator();
        for (RubyClass c = clazz.getSuperClass(); allocator == null && c != null; c = c.getSuperClass()) {
            allocator = c.getAllocator();
        }
        if (allocator == null
                || allocator == RubyObject.IVAR_INSPECTING_OBJECT_ALLOCATOR
                || allocator == RubyObject.REIFYING_OBJECT_ALLOCATOR) {
            return RubyObject.OBJECT_ALLOCATOR;
        }
        return allocator;
    }
}
