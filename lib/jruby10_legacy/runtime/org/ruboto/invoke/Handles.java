package org.ruboto.invoke;

import java.lang.reflect.Array;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;

/** MethodHandle implementations backed by reflection and plain Java. */
final class Handles {
    private Handles() {}

    static final Object[] NO_ARGS = new Object[0];

    /** Rethrows the cause of a reflective invocation without wrapping it. */
    static Throwable unwrap(InvocationTargetException e) {
        return e.getCause() == null ? e : e.getCause();
    }

    static Object[] copyOfRange(Object[] args, int from, int to) {
        Object[] r = new Object[to - from];
        System.arraycopy(args, from, r, 0, to - from);
        return r;
    }

    static Object[] collect(Object[] args, int pos, int count, Class<?> componentType) {
        Object array = Array.newInstance(componentType, count);
        for (int i = 0; i < count; i++) Array.set(array, i, args[pos + i]);
        Object[] r = new Object[args.length - count + 1];
        System.arraycopy(args, 0, r, 0, pos);
        r[pos] = array;
        System.arraycopy(args, pos + count, r, pos + 1, args.length - pos - count);
        return r;
    }

    static MethodType typeOf(Method m) {
        Class<?>[] params = m.getParameterTypes();
        if (Modifier.isStatic(m.getModifiers())) return MethodType.methodType(m.getReturnType(), params);
        return MethodType.methodType(m.getReturnType(), params).insertParameterTypes(0, m.getDeclaringClass());
    }

    static final class StaticMethod extends MethodHandle {
        private final Method method;

        StaticMethod(Method method) {
            super(typeOf(method));
            this.method = method;
            method.setAccessible(true);
        }

        @Override
        public Object invokeArgs(Object[] args) throws Throwable {
            try {
                return method.invoke(null, args);
            } catch (InvocationTargetException e) {
                throw unwrap(e);
            }
        }

        @Override
        public String toString() { return "MethodHandle(static " + method + ")"; }
    }

    static final class VirtualMethod extends MethodHandle {
        private final Method method;

        VirtualMethod(Method method, Class<?> receiver) {
            super(typeOf(method).changeParameterType(0, receiver));
            this.method = method;
            method.setAccessible(true);
        }

        @Override
        public Object invokeArgs(Object[] args) throws Throwable {
            Object receiver = args[0];
            if (receiver == null) throw new NullPointerException("receiver for " + method);
            try {
                return method.invoke(receiver, copyOfRange(args, 1, args.length));
            } catch (InvocationTargetException e) {
                throw unwrap(e);
            }
        }

        @Override
        public String toString() { return "MethodHandle(" + method + ")"; }
    }

    static final class ConstructorHandle extends MethodHandle {
        private final Constructor<?> constructor;

        ConstructorHandle(Constructor<?> constructor) {
            super(MethodType.methodType(constructor.getDeclaringClass(), constructor.getParameterTypes()));
            this.constructor = constructor;
            constructor.setAccessible(true);
        }

        @Override
        public Object invokeArgs(Object[] args) throws Throwable {
            try {
                return constructor.newInstance(args);
            } catch (InvocationTargetException e) {
                throw unwrap(e);
            }
        }

        @Override
        public String toString() { return "MethodHandle(" + constructor + ")"; }
    }

    static final class Getter extends MethodHandle {
        private final Field field;
        private final boolean isStatic;

        Getter(Field field) {
            super(Modifier.isStatic(field.getModifiers())
                    ? MethodType.methodType(field.getType())
                    : MethodType.methodType(field.getType(), field.getDeclaringClass()));
            this.field = field;
            this.isStatic = Modifier.isStatic(field.getModifiers());
            field.setAccessible(true);
        }

        @Override
        public Object invokeArgs(Object[] args) throws Throwable {
            return field.get(isStatic ? null : args[0]);
        }
    }

    static final class Setter extends MethodHandle {
        private final Field field;
        private final boolean isStatic;

        Setter(Field field) {
            super(Modifier.isStatic(field.getModifiers())
                    ? MethodType.methodType(void.class, field.getType())
                    : MethodType.methodType(void.class, field.getDeclaringClass(), field.getType()));
            this.field = field;
            this.isStatic = Modifier.isStatic(field.getModifiers());
            field.setAccessible(true);
        }

        @Override
        public Object invokeArgs(Object[] args) throws Throwable {
            if (isStatic) field.set(null, args[0]);
            else field.set(args[0], args[1]);
            return null;
        }
    }

    /** asType/explicitCastArguments: converts arguments and the return value. */
    static final class Converting extends MethodHandle {
        private final MethodHandle target;

        Converting(MethodHandle target, MethodType newType) {
            super(newType);
            this.target = target;
        }

        @Override
        public Object invokeArgs(Object[] args) throws Throwable {
            MethodType targetType = target.type;
            Object[] converted = args;
            for (int i = 0; i < args.length; i++) {
                Class<?> to = targetType.parameterType(i);
                if (to.isPrimitive()) {
                    if (converted == args) converted = args.clone();
                    converted[i] = Primitives.convert(args[i], to);
                }
            }
            Object result = target.invokeArgs(converted);
            return Primitives.convert(result, type.returnType());
        }

        @Override
        public MethodHandle asType(MethodType newType) {
            return target.asType(newType);
        }
    }

    static final class VarargsCollector extends MethodHandle {
        private final MethodHandle target;
        private final Class<?> arrayType;

        VarargsCollector(MethodHandle target, Class<?> arrayType) {
            super(target.type);
            this.target = target;
            this.arrayType = arrayType;
        }

        @Override
        public Object invokeArgs(Object[] args) throws Throwable {
            return target.invokeArgs(args);
        }

        @Override
        public Object invokeWithArguments(Object... args) throws Throwable {
            int fixed = type.parameterCount() - 1;
            if (args.length == type.parameterCount()) {
                Object last = args[fixed];
                if (last == null || arrayType.isInstance(last)) return target.invokeArgs(args);
            }
            return target.invokeArgs(collect(args, fixed, args.length - fixed, arrayType.getComponentType()));
        }

        @Override
        public boolean isVarargsCollector() { return true; }

        @Override
        public MethodHandle asFixedArity() { return target; }
    }

    static final class Constant extends MethodHandle {
        private final Object value;

        Constant(Class<?> type, Object value) {
            super(MethodType.methodType(type));
            this.value = Primitives.convert(value, type);
        }

        @Override
        public Object invokeArgs(Object[] args) { return value; }
    }

    static final class Identity extends MethodHandle {
        Identity(Class<?> type) {
            super(MethodType.methodType(type, type));
        }

        @Override
        public Object invokeArgs(Object[] args) { return args[0]; }
    }

    /** A handle whose target is looked up each call; used by CallSite.dynamicInvoker. */
    static final class Dynamic extends MethodHandle {
        private final CallSite site;

        Dynamic(CallSite site) {
            super(site.type());
            this.site = site;
        }

        @Override
        public Object invokeArgs(Object[] args) throws Throwable {
            return site.getTarget().invokeArgs(args);
        }
    }

    /** Placeholder for operations that need runtime bytecode generation. */
    static final class Unsupported extends MethodHandle {
        private final String what;

        Unsupported(MethodType type, String what) {
            super(type);
            this.what = what;
        }

        @Override
        public Object invokeArgs(Object[] args) {
            throw new UnsupportedOperationException(what + " is not supported on this Android version");
        }
    }
}
