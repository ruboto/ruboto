package org.ruboto.invoke;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

/**
 * Stand-in for java.lang.invoke.MethodType on Android versions without
 * java.lang.invoke (API < 26).  jruby-core is rewritten at build time to use
 * this package instead of java.lang.invoke; see LegacyAndroidPatcher.
 */
public final class MethodType {
    private static final Class<?>[] NO_PTYPES = new Class<?>[0];

    private final Class<?> rtype;
    private final Class<?>[] ptypes;

    private MethodType(Class<?> rtype, Class<?>[] ptypes) {
        if (rtype == null) throw new NullPointerException("rtype");
        for (Class<?> p : ptypes) {
            if (p == null) throw new NullPointerException("ptype");
            if (p == void.class) throw new IllegalArgumentException("parameter type cannot be void");
        }
        this.rtype = rtype;
        this.ptypes = ptypes;
    }

    public static MethodType methodType(Class<?> rtype, Class<?>[] ptypes) {
        return new MethodType(rtype, ptypes.clone());
    }

    public static MethodType methodType(Class<?> rtype, List<Class<?>> ptypes) {
        return new MethodType(rtype, ptypes.toArray(NO_PTYPES));
    }

    public static MethodType methodType(Class<?> rtype, Class<?> ptype0, Class<?>... ptypes) {
        Class<?>[] all = new Class<?>[ptypes.length + 1];
        all[0] = ptype0;
        System.arraycopy(ptypes, 0, all, 1, ptypes.length);
        return new MethodType(rtype, all);
    }

    public static MethodType methodType(Class<?> rtype) {
        return new MethodType(rtype, NO_PTYPES);
    }

    public static MethodType methodType(Class<?> rtype, Class<?> ptype0) {
        return new MethodType(rtype, new Class<?>[]{ptype0});
    }

    public static MethodType methodType(Class<?> rtype, MethodType ptypes) {
        return new MethodType(rtype, ptypes.ptypes);
    }

    public static MethodType genericMethodType(int objectArgCount, boolean finalArray) {
        Class<?>[] p = new Class<?>[objectArgCount + (finalArray ? 1 : 0)];
        Arrays.fill(p, Object.class);
        if (finalArray) p[objectArgCount] = Object[].class;
        return new MethodType(Object.class, p);
    }

    public static MethodType genericMethodType(int objectArgCount) {
        return genericMethodType(objectArgCount, false);
    }

    public Class<?> returnType() { return rtype; }

    public Class<?> parameterType(int num) { return ptypes[num]; }

    public int parameterCount() { return ptypes.length; }

    public Class<?>[] parameterArray() { return ptypes.clone(); }

    public List<Class<?>> parameterList() { return Collections.unmodifiableList(Arrays.asList(ptypes)); }

    public Class<?> lastParameterType() { return ptypes.length == 0 ? void.class : ptypes[ptypes.length - 1]; }

    public MethodType changeReturnType(Class<?> nrtype) { return new MethodType(nrtype, ptypes); }

    public MethodType changeParameterType(int num, Class<?> nptype) {
        Class<?>[] p = ptypes.clone();
        p[num] = nptype;
        return new MethodType(rtype, p);
    }

    public MethodType insertParameterTypes(int num, Class<?>... ptypesToInsert) {
        if (num < 0 || num > ptypes.length) throw new IndexOutOfBoundsException(Integer.toString(num));
        Class<?>[] p = new Class<?>[ptypes.length + ptypesToInsert.length];
        System.arraycopy(ptypes, 0, p, 0, num);
        System.arraycopy(ptypesToInsert, 0, p, num, ptypesToInsert.length);
        System.arraycopy(ptypes, num, p, num + ptypesToInsert.length, ptypes.length - num);
        return new MethodType(rtype, p);
    }

    public MethodType insertParameterTypes(int num, List<Class<?>> ptypesToInsert) {
        return insertParameterTypes(num, ptypesToInsert.toArray(NO_PTYPES));
    }

    public MethodType appendParameterTypes(Class<?>... ptypesToInsert) {
        return insertParameterTypes(ptypes.length, ptypesToInsert);
    }

    public MethodType appendParameterTypes(List<Class<?>> ptypesToInsert) {
        return insertParameterTypes(ptypes.length, ptypesToInsert);
    }

    public MethodType dropParameterTypes(int start, int end) {
        if (start < 0 || start > end || end > ptypes.length) {
            throw new IndexOutOfBoundsException("start=" + start + " end=" + end);
        }
        Class<?>[] p = new Class<?>[ptypes.length - (end - start)];
        System.arraycopy(ptypes, 0, p, 0, start);
        System.arraycopy(ptypes, end, p, start, ptypes.length - end);
        return new MethodType(rtype, p);
    }

    public boolean hasPrimitives() {
        if (rtype.isPrimitive()) return true;
        for (Class<?> p : ptypes) if (p.isPrimitive()) return true;
        return false;
    }

    public boolean hasWrappers() {
        if (Primitives.isWrapper(rtype)) return true;
        for (Class<?> p : ptypes) if (Primitives.isWrapper(p)) return true;
        return false;
    }

    public MethodType erase() {
        Class<?>[] p = new Class<?>[ptypes.length];
        for (int i = 0; i < p.length; i++) p[i] = ptypes[i].isPrimitive() ? ptypes[i] : Object.class;
        return new MethodType(rtype.isPrimitive() ? rtype : Object.class, p);
    }

    public MethodType generic() {
        return genericMethodType(ptypes.length);
    }

    public MethodType wrap() {
        Class<?>[] p = new Class<?>[ptypes.length];
        for (int i = 0; i < p.length; i++) p[i] = Primitives.wrap(ptypes[i]);
        return new MethodType(Primitives.wrap(rtype), p);
    }

    public MethodType unwrap() {
        Class<?>[] p = new Class<?>[ptypes.length];
        for (int i = 0; i < p.length; i++) p[i] = Primitives.unwrap(ptypes[i]);
        return new MethodType(Primitives.unwrap(rtype), p);
    }

    public String toMethodDescriptorString() {
        StringBuilder sb = new StringBuilder("(");
        for (Class<?> p : ptypes) sb.append(descriptor(p));
        return sb.append(')').append(descriptor(rtype)).toString();
    }

    private static String descriptor(Class<?> c) {
        if (c.isArray()) return c.getName().replace('.', '/');
        if (c == void.class) return "V";
        if (c == boolean.class) return "Z";
        if (c == byte.class) return "B";
        if (c == char.class) return "C";
        if (c == short.class) return "S";
        if (c == int.class) return "I";
        if (c == long.class) return "J";
        if (c == float.class) return "F";
        if (c == double.class) return "D";
        return "L" + c.getName().replace('.', '/') + ";";
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof MethodType)) return false;
        MethodType other = (MethodType) o;
        return rtype == other.rtype && Arrays.equals(ptypes, other.ptypes);
    }

    @Override
    public int hashCode() {
        return 31 * rtype.hashCode() + Arrays.hashCode(ptypes);
    }

    @Override
    public String toString() {
        List<String> names = new ArrayList<String>(ptypes.length);
        for (Class<?> p : ptypes) names.add(p.getSimpleName());
        StringBuilder sb = new StringBuilder("(");
        for (int i = 0; i < names.size(); i++) {
            if (i > 0) sb.append(',');
            sb.append(names.get(i));
        }
        return sb.append(')').append(rtype.getSimpleName()).toString();
    }
}
