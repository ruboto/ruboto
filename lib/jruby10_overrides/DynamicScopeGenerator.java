package org.jruby.runtime.scope;

import java.lang.invoke.MethodHandle;
import java.util.Collections;
import java.util.List;

/**
 * Android (ART) replacement for JRuby's DynamicScopeGenerator.  ART cannot
 * define JVM bytecode at runtime, so instead of generating specialized
 * scope classes every scope uses the generic ManyVarsDynamicScope.
 */
public class DynamicScopeGenerator {
    public static final String SCOPES_PACKAGE = "org.jruby.runtime.scopes";
    public static final String SCOPES_PATH = SCOPES_PACKAGE.replace('.', '/');
    public static final List<String> SPECIALIZED_GETS = Collections.emptyList();
    public static final List<String> SPECIALIZED_GETS_OR_NIL = Collections.emptyList();
    public static final List<String> SPECIALIZED_SETS = Collections.emptyList();

    public static MethodHandle generate(final int size) {
        return ManyVarsDynamicScope.CONSTRUCTOR;
    }
}
