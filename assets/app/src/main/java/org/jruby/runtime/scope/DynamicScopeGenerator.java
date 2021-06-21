package org.jruby.runtime.scope;

import com.android.dx.BinaryOp;
import com.android.dx.Code;
import com.android.dx.Comparison;
import com.android.dx.DexMaker;
import com.android.dx.FieldId;
import com.android.dx.Local;
import com.android.dx.MethodId;
import com.android.dx.TypeId;

import org.jruby.Ruby;
import org.jruby.parser.StaticScope;
import org.jruby.runtime.DynamicScope;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ClassDefiningClassLoader;
import org.jruby.util.OneShotClassLoader;
import org.jruby.util.collections.NonBlockingHashMapLong;

import java.io.IOException;
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.lang.reflect.Modifier;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import me.qmx.jitescript.JDKVersion;
import me.qmx.jitescript.JiteClass;

import static org.jruby.util.CodegenUtils.p;

/**
 * A generator for DynamicScope subclasses, using fields for storage and specializing appropriate methods.
 */
public class DynamicScopeGenerator {
    private static final NonBlockingHashMapLong<MethodHandle> specializedFactories = new NonBlockingHashMapLong<>();
    private static ClassDefiningClassLoader CDCL = new OneShotClassLoader(Ruby.getClassLoader());

    public static final List<String> SPECIALIZED_GETS = Collections.unmodifiableList(Arrays.asList(
            "getValueZeroDepthZero",
            "getValueOneDepthZero",
            "getValueTwoDepthZero",
            "getValueThreeDepthZero",
            "getValueFourDepthZero",
            "getValueFiveDepthZero",
            "getValueSixDepthZero",
            "getValueSevenDepthZero",
            "getValueEightDepthZero",
            "getValueNineDepthZero"
    ));

    public static final List<String> SPECIALIZED_GETS_OR_NIL = Collections.unmodifiableList(Arrays.asList(
            "getValueZeroDepthZeroOrNil",
            "getValueOneDepthZeroOrNil",
            "getValueTwoDepthZeroOrNil",
            "getValueThreeDepthZeroOrNil",
            "getValueFourDepthZeroOrNil",
            "getValueFiveDepthZeroOrNil",
            "getValueSixDepthZeroOrNil",
            "getValueSevenDepthZeroOrNil",
            "getValueEightDepthZeroOrNil",
            "getValueNineDepthZeroOrNil"
    ));

    public static final List<String> SPECIALIZED_SETS = Collections.unmodifiableList(Arrays.asList(
            "setValueZeroDepthZeroVoid",
            "setValueOneDepthZeroVoid",
            "setValueTwoDepthZeroVoid",
            "setValueThreeDepthZeroVoid",
            "setValueFourDepthZeroVoid",
            "setValueFiveDepthZeroVoid",
            "setValueSixDepthZeroVoid",
            "setValueSevenDepthZeroVoid",
            "setValueEightDepthZeroVoid",
            "setValueNineDepthZeroVoid"
    ));

    public static MethodHandle generate(final int size) {
        MethodHandle h = getClassFromSize(size);

        if (h != null) return h;

        final String clsPath = "org/jruby/runtime/scopes/DynamicScope" + size;
        final String clsName = clsPath.replaceAll("/", ".");

        // try to load the class, in case we have parallel generation happening
        Class p;

        try {
            p = CDCL.loadClass(clsName);
        } catch (ClassNotFoundException cnfe) {
            // try again under lock
            synchronized (CDCL) {
                try {
                    p = CDCL.loadClass(clsName);
                } catch (ClassNotFoundException cnfe2) {
                    // proceed to actually generate the class
                    try {
                        p = generateDex(size, clsPath, clsName);
                    } catch (IOException | ClassNotFoundException e) {
                        throw new RuntimeException(e);
                    }
                }
            }
        }

        // acquire constructor handle and store it
        try {
//            MethodHandle mh = MethodHandles.lookup().findStatic(p, "newScope", MethodType.methodType(DynamicScope.class, StaticScope.class, DynamicScope.class));
            MethodHandle mh = MethodHandles.lookup().findConstructor(p, MethodType.methodType(void.class, StaticScope.class, DynamicScope.class));
//            mh = mh.asType(MethodType.methodType(p, StaticScope.class, DynamicScope.class));
            MethodHandle previousMH = specializedFactories.putIfAbsent(size, mh);
            if (previousMH != null) mh = previousMH;

            return mh;
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static <T, G extends T> void generateConstructor(DexMaker dexMaker, TypeId<G> generatedType, TypeId<T> superType) {
        TypeId<?>[] paramTypes = new TypeId<?>[2];
        paramTypes[0] = TypeId.get(StaticScope.class);
        paramTypes[1] = TypeId.get(DynamicScope.class);

        MethodId<?, ?> constructor = generatedType.getMethod(TypeId.VOID, "<init>", paramTypes);
        Code code = dexMaker.declare(constructor, Modifier.PUBLIC);
        MethodId<T, ?> superConstructor = superType.getConstructor(paramTypes);
        Local<?>[] params = new Local<?>[2];
        params[0] = code.getParameter(0, paramTypes[0]);
        params[1] = code.getParameter(1, paramTypes[1]);
        Local<G> thisLocal = code.getThis(generatedType);
        code.invokeDirect(superConstructor, null, thisLocal, params);
        code.returnVoid();
    }

    private static <T extends DynamicScope> Class<?> generateDex(final int size, final String clsPath, final String clsName) throws IOException, ClassNotFoundException {
        // ensure only one thread will attempt to generate and define the new class
        synchronized (CDCL) {
            // create a new one
            final String[] newFields = varList(size);

            final String baseName = p(DynamicScope.class);

            DexMaker dexMaker = new DexMaker();
            TypeId<T> dexClass = TypeId.get("L" + clsPath + ";");
            TypeId<DynamicScope> baseClass = TypeId.get("L" + baseName + ";");
            dexMaker.declare(dexClass, clsName + ".generated", Modifier.PUBLIC, baseClass);
            generateConstructor(dexMaker, dexClass, baseClass);
            TypeId<IRubyObject> iRubyObjectTypeId = TypeId.get(IRubyObject.class);


            TypeId<StaticScope> staticScopeTypeId = TypeId.get(StaticScope.class);
            TypeId<DynamicScope> dynamicScopeTypeId = TypeId.get(DynamicScope.class);
            TypeId<RuntimeException> runtimeExceptionTypeId = TypeId.get(RuntimeException.class);

            generateNewScopeMethod(dexMaker, dexClass, staticScopeTypeId, dynamicScopeTypeId);

            // getValue
            MethodId<T, IRubyObject> getValueMethod = dexClass.getMethod(iRubyObjectTypeId, "getValue", TypeId.INT, TypeId.INT);
            Code code = dexMaker.declare(getValueMethod, Modifier.PUBLIC);
            Local<Integer> depth = code.getParameter(1, TypeId.INT);
            Local<Integer> zero = code.newLocal(TypeId.INT);
            Local<Integer> one = code.newLocal(TypeId.INT);
            com.android.dx.Label parentCall = new com.android.dx.Label();
            Local<RuntimeException> sizeErrorVar = code.newLocal(runtimeExceptionTypeId);
            Local<Integer> offset = code.getParameter(0, TypeId.INT);
            Local<DynamicScope> parent = code.newLocal(baseClass);
            Local<T> thisLocal = code.getThis(dexClass);
            Local<IRubyObject> result = code.newLocal(iRubyObjectTypeId);
            Local<Integer>[] compareValues = new Local[size];
            for (int i = 0; i < size; i++) {
                compareValues[i] = code.newLocal(TypeId.INT);
            }
            for (int i = 0; i < size; i++) {
                code.loadConstant(compareValues[i], i);
            }
            code.loadConstant(zero, 0);

            code.compare(Comparison.NE, parentCall, depth, zero);

            if (size > 0) {
                com.android.dx.Label defaultError = new com.android.dx.Label();
                com.android.dx.Label[] cases = new com.android.dx.Label[size];


                for (int i = 0; i < size; i++) {
                    cases[i] = new com.android.dx.Label();
                    code.compare(Comparison.EQ, cases[i], offset, compareValues[i]);
                }
                code.jump(defaultError);
                for (int i = 0; i < size; i++) {
                    code.mark(cases[i]);
                    FieldId<T, IRubyObject> selectedField = dexClass.getField(iRubyObjectTypeId, newFields[i]);
                    code.iget(selectedField, result, thisLocal);
                    code.returnValue(result);
                }
                code.mark(defaultError);
            }

            MethodId<T, RuntimeException> sizeErrorMethod = dexClass.getMethod(runtimeExceptionTypeId, "sizeError");
            code.invokeStatic(sizeErrorMethod, sizeErrorVar);
            code.throwValue(sizeErrorVar);

            code.mark(parentCall);
            FieldId<T, DynamicScope> parentField = dexClass.getField(baseClass, "parent");
            code.iget(parentField, parent, thisLocal);
            MethodId<DynamicScope, IRubyObject> parentMethod = baseClass.getMethod(iRubyObjectTypeId, "getValue", TypeId.INT, TypeId.INT);
            code.loadConstant(one, 1);
            code.op(BinaryOp.SUBTRACT, depth, depth, one);
            code.invokeVirtual(parentMethod, result, parent, offset, depth);
            code.returnValue(result);

            // setValueVoid
            MethodId<T, Void> setValueVoidMethod = dexClass.getMethod(TypeId.VOID, "setValueVoid", iRubyObjectTypeId, TypeId.INT, TypeId.INT);
            code = dexMaker.declare(setValueVoidMethod, Modifier.PUBLIC);
            depth = code.getParameter(2, TypeId.INT);
            zero = code.newLocal(TypeId.INT);
            sizeErrorVar = code.newLocal(runtimeExceptionTypeId);
            offset = code.getParameter(1, TypeId.INT);
            // parent = code.newLocal(baseClass);
            thisLocal = code.getThis(dexClass);
            Local<IRubyObject> value = code.getParameter(0, iRubyObjectTypeId);
            for (int i = 0; i < size; i++) {
                compareValues[i] = code.newLocal(TypeId.INT);
            }
            for (int i = 0; i < size; i++) {
                code.loadConstant(compareValues[i], i);
            }
            parentCall = new com.android.dx.Label();
            code.loadConstant(zero, 0);
            code.compare(Comparison.NE, parentCall, depth, zero);
            if (size > 0) {
                com.android.dx.Label defaultError = new com.android.dx.Label();
                com.android.dx.Label[] cases = new com.android.dx.Label[size];

                for (int i = 0; i < size; i++) {
                    cases[i] = new com.android.dx.Label();
                    code.compare(Comparison.EQ, cases[i], offset, compareValues[i]);
                }
                code.jump(defaultError);
                for (int i = 0; i < size; i++) {
                    code.mark(cases[i]);
                    FieldId<T, IRubyObject> selectedField = dexClass.getField(iRubyObjectTypeId, newFields[i]);
                    code.iput(selectedField, thisLocal, value);
                    code.returnVoid();
                }
                code.mark(defaultError);
            }

            sizeErrorMethod = dexClass.getMethod(runtimeExceptionTypeId, "sizeError");
            code.invokeStatic(sizeErrorMethod, sizeErrorVar);
            code.throwValue(sizeErrorVar);

            code.mark(parentCall);
            // DynamicScope;.setValueVoid is abstract, so this cannot work :(
            /* parentField = dexClass.getField(baseClass, "parent");
            code.iget(parentField, parent, thisLocal);
            MethodId<DynamicScope, Void> parentSetValueVoid = baseClass.getMethod(TypeId.VOID, "setValueVoid", iRubyObjectTypeId, TypeId.INT, TypeId.INT);
            code.invokeVirtual(parentSetValueVoid, null, parent, offset, depth); */
            code.returnVoid();

            // getValueDepthZero
            MethodId<T, IRubyObject> getValueDepthZeroMethod = dexClass.getMethod(iRubyObjectTypeId, "getValueDepthZero", TypeId.INT);
            code = dexMaker.declare(getValueDepthZeroMethod, Modifier.PUBLIC);
            sizeErrorVar = code.newLocal(runtimeExceptionTypeId);
            result = code.newLocal(iRubyObjectTypeId);
            offset = code.getParameter(0, TypeId.INT);
            thisLocal = code.getThis(dexClass);
            for (int i = 0; i < size; i++) {
                compareValues[i] = code.newLocal(TypeId.INT);
            }
            for (int i = 0; i < size; i++) {
                code.loadConstant(compareValues[i], i);
            }
            if (size > 0) {
                com.android.dx.Label defaultError = new com.android.dx.Label();
                com.android.dx.Label[] cases = new com.android.dx.Label[size];
                for (int i = 0; i < size; i++) {
                    cases[i] = new com.android.dx.Label();
                    code.compare(Comparison.EQ, cases[i], offset, compareValues[i]);
                }
                code.jump(defaultError);
                for (int i = 0; i < size; i++) {
                    code.mark(cases[i]);
                    FieldId<T, IRubyObject> selectedField = dexClass.getField(iRubyObjectTypeId, newFields[i]);
                    code.iget(selectedField, result, thisLocal);
                    code.returnValue(result);
                }
                code.mark(defaultError);
            }
            sizeErrorMethod = dexClass.getMethod(runtimeExceptionTypeId, "sizeError");
            code.invokeStatic(sizeErrorMethod, sizeErrorVar);
            code.throwValue(sizeErrorVar);

            // setValueDepthZero
            MethodId<T, IRubyObject> setValueDepthZeroMethod = dexClass.getMethod(iRubyObjectTypeId, "setValueDepthZero", iRubyObjectTypeId, TypeId.INT);
            code = dexMaker.declare(setValueDepthZeroMethod, Modifier.PUBLIC);
            offset = code.getParameter(1, TypeId.INT);
            value = code.getParameter(0, iRubyObjectTypeId);
            sizeErrorVar = code.newLocal(runtimeExceptionTypeId);
            for (int i = 0; i < size; i++) {
                compareValues[i] = code.newLocal(TypeId.INT);
            }
            for (int i = 0; i < size; i++) {
                code.loadConstant(compareValues[i], i);
            }
            thisLocal = code.getThis(dexClass);
            if (size > 0) {
                com.android.dx.Label defaultError = new com.android.dx.Label();
                com.android.dx.Label[] cases = new com.android.dx.Label[size];
                for (int i = 0; i < size; i++) {
                    cases[i] = new com.android.dx.Label();
                    code.compare(Comparison.EQ, cases[i], offset, compareValues[i]);
                }
                code.jump(defaultError);
                for (int i = 0; i < size; i++) {
                    code.mark(cases[i]);
                    FieldId<T, IRubyObject> selectedField = dexClass.getField(iRubyObjectTypeId, newFields[i]);
                    code.iput(selectedField, thisLocal, value);
                    code.returnValue(value);
                }
                code.mark(defaultError);
            }
            sizeErrorMethod = dexClass.getMethod(runtimeExceptionTypeId, "sizeError");
            code.invokeStatic(sizeErrorMethod, sizeErrorVar);
            code.throwValue(sizeErrorVar);

            // SPECIALIZED_GETS
            for (int i = 0; i < SPECIALIZED_GETS.size(); i++) {
                final int currentOffset = i;

                MethodId<T, IRubyObject> newMethod = dexClass.getMethod(iRubyObjectTypeId, SPECIALIZED_GETS.get(currentOffset));
                code = dexMaker.declare(newMethod, Modifier.PUBLIC);
                if (size <= currentOffset) {
                    sizeErrorVar = code.newLocal(runtimeExceptionTypeId);
                    sizeErrorMethod = dexClass.getMethod(runtimeExceptionTypeId, "sizeError");
                    code.invokeStatic(sizeErrorMethod, sizeErrorVar);
                    code.throwValue(sizeErrorVar);
                } else {
                    result = code.newLocal(iRubyObjectTypeId);
                    FieldId<T, IRubyObject> selectedField = dexClass.getField(iRubyObjectTypeId, newFields[currentOffset]);
                    thisLocal = code.getThis(dexClass);
                    code.iget(selectedField, result, thisLocal);
                    code.returnValue(result);
                }
            }

            // SPECIALIZED_GETS_OR_NIL
            for (int i = 0; i < SPECIALIZED_GETS_OR_NIL.size(); i++) {
                final int currentOffset = i;
                MethodId<T, IRubyObject> newMethod = dexClass.getMethod(iRubyObjectTypeId, SPECIALIZED_GETS_OR_NIL.get(currentOffset), iRubyObjectTypeId);
                code = dexMaker.declare(newMethod, Modifier.PUBLIC);
                if (size <= currentOffset) {
                    sizeErrorVar = code.newLocal(runtimeExceptionTypeId);
                    sizeErrorMethod = dexClass.getMethod(runtimeExceptionTypeId, "sizeError");
                    code.invokeStatic(sizeErrorMethod, sizeErrorVar);
                    code.throwValue(sizeErrorVar);
                } else {
                    thisLocal = code.getThis(dexClass);
                    value = code.newLocal(iRubyObjectTypeId);
                    Local<IRubyObject> nullValue = code.newLocal(iRubyObjectTypeId);
                    Local<IRubyObject> nilParam = code.getParameter(0, iRubyObjectTypeId);
                    code.loadConstant(nullValue, null);
                    FieldId<T, IRubyObject> selectedField = dexClass.getField(iRubyObjectTypeId, newFields[currentOffset]);
                    code.iget(selectedField, value, thisLocal);
                    com.android.dx.Label ok = new com.android.dx.Label();
                    code.compare(Comparison.NE, ok, value, nullValue);
                    code.iput(selectedField, thisLocal, nilParam);
                    code.returnValue(nilParam);
                    code.mark(ok);
                    code.returnValue(value);
                }
            }

            // SPECIALIZED_SETS
            for (int i = 0; i < SPECIALIZED_SETS.size(); i++) {
                final int currentOffset = i;
                MethodId<T, Void> newMethod = dexClass.getMethod(TypeId.VOID, SPECIALIZED_SETS.get(currentOffset), iRubyObjectTypeId);
                code = dexMaker.declare(newMethod, Modifier.PUBLIC);
                if (size <= currentOffset) {
                    sizeErrorVar = code.newLocal(runtimeExceptionTypeId);
                    sizeErrorMethod = dexClass.getMethod(runtimeExceptionTypeId, "sizeError");
                    code.invokeStatic(sizeErrorMethod, sizeErrorVar);
                    code.throwValue(sizeErrorVar);
                } else {
                    thisLocal = code.getThis(dexClass);
                    value = code.getParameter(0, iRubyObjectTypeId);
                    FieldId<T, IRubyObject> selectedField = dexClass.getField(iRubyObjectTypeId, newFields[currentOffset]);

                    code.iput(selectedField, thisLocal, value);
                    code.returnVoid();
                }
            }

            // fields
            for (String prop : newFields) {
                FieldId<T, IRubyObject> newField = dexClass.getField(iRubyObjectTypeId, prop);
                dexMaker.declare(newField, Modifier.PUBLIC, null);
            }

            // utilities
            // Method "sizeError"
            MethodId<T, RuntimeException> sizeErrorMethodId = dexClass.getMethod(runtimeExceptionTypeId, "sizeError");
            code = dexMaker.declare(sizeErrorMethodId, Modifier.PRIVATE | Modifier.STATIC);
            Local<String> message = code.newLocal(TypeId.STRING);
            Local<RuntimeException> returnValue = code.newLocal(runtimeExceptionTypeId);
            code.loadConstant(message, clsName + " only supports scopes with " + size + " variables");
            MethodId<RuntimeException, Void> runtimeExceptionInit = runtimeExceptionTypeId.getMethod(TypeId.VOID, "<init>", TypeId.STRING);
            code.newInstance(returnValue, runtimeExceptionInit, message);
            code.returnValue(returnValue);

            ClassLoader loader = dexMaker.generateAndLoad((ClassLoader) CDCL, null);
            return loader.loadClass(clsName);
        }
    }

    // static scope constructor method to work around Android not handling invokeExact right
    private static <T extends DynamicScope> void generateNewScopeMethod(DexMaker dexMaker, TypeId<T> dexClass, TypeId<StaticScope> staticScopeTypeId, TypeId<DynamicScope> dynamicScopeTypeId) {
        MethodId<T, DynamicScope> newScopeMethod = dexClass.getMethod(dynamicScopeTypeId, "newScope", staticScopeTypeId, dynamicScopeTypeId);
        Code code = dexMaker.declare(newScopeMethod, Modifier.PUBLIC | Modifier.STATIC);
        Local<StaticScope> staticScopeParam = code.getParameter(0, staticScopeTypeId);
        Local<DynamicScope> dynamicScopeParam = code.getParameter(1, dynamicScopeTypeId);
        Local<DynamicScope> newScopeReturnValue = code.newLocal(dynamicScopeTypeId);
        MethodId<T, DynamicScope> constructor = dexClass.getMethod(dynamicScopeTypeId, "<init>", staticScopeTypeId, dynamicScopeTypeId);
        code.invokeStatic(constructor, newScopeReturnValue, staticScopeParam, dynamicScopeParam);
        code.returnValue(newScopeReturnValue);
    }

    private static MethodHandle getClassFromSize(int size) {
        return specializedFactories.get(size);
    }

    private static Class defineClass(JiteClass jiteClass) {
        return CDCL.defineClass(classNameFromJiteClass(jiteClass), jiteClass.toBytes(JDKVersion.V1_7));
    }

    private static Class loadClass(JiteClass jiteClass) throws ClassNotFoundException {
        return CDCL.loadClass(classNameFromJiteClass(jiteClass));
    }

    private static String classNameFromJiteClass(JiteClass jiteClass) {
        return jiteClass.getClassName().replaceAll("/", ".");
    }

    private static String[] varList(int size) {
        String[] vars = new String[size];

        for (int i = 0; i < size; i++) {
            vars[i] = "var" + i;
        }

        return vars;
    }
}
