import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Stream;

import org.jruby.org.objectweb.asm.ClassReader;
import org.jruby.org.objectweb.asm.ClassVisitor;
import org.jruby.org.objectweb.asm.ClassWriter;
import org.jruby.org.objectweb.asm.Handle;
import org.jruby.org.objectweb.asm.MethodVisitor;
import org.jruby.org.objectweb.asm.Opcodes;
import org.jruby.org.objectweb.asm.Type;
import org.jruby.org.objectweb.asm.commons.ClassRemapper;
import org.jruby.org.objectweb.asm.commons.MethodRemapper;
import org.jruby.org.objectweb.asm.commons.Remapper;

/**
 * Makes a tree of jruby-core .class files run on Android versions that lack
 * java.lang.invoke (API < 26) or VarHandle (API < 33).
 *
 * 1. References to java.lang.invoke.* are relocated to org.ruboto.invoke.*,
 *    a reflection/Unsafe-based stand-in (see runtime/).  invokedynamic
 *    bootstrap methods are left alone: those are LambdaMetafactory,
 *    StringConcatFactory, ObjectMethods and SwitchBootstraps, which d8
 *    desugars away.  java.lang.ClassValue (API 34) is relocated to
 *    org.ruboto.compat.ClassValue.
 *
 * 2. Signature-polymorphic calls (MethodHandle.invoke/invokeExact and the
 *    VarHandle access methods) become INVOKESTATIC calls to bridge methods
 *    generated into org.ruboto.invoke.Poly, which box the arguments and call
 *    MethodHandle.invokeArgs / VarHandle.access.
 *
 * 3. Calls to Java APIs newer than the device that d8 does not backport are
 *    retargeted to static helpers in org.ruboto.compat.Backports, also when
 *    they are made through a subclass (e.g. ByteArrayInputStream.readAllBytes)
 *    that does not override the method in the class tree itself.
 *
 * Every rewrite preserves the operand stack shape, so existing stack map
 * frames stay valid.
 *
 * Uses the ASM that jruby-core bundles (org.jruby.org.objectweb.asm), so no
 * extra library is needed.  Run it from a copy of those classes, not from the
 * tree being patched.
 *
 * Usage: java LegacyAndroidPatcher <class tree root>
 */
public class LegacyAndroidPatcher {
    static final String SHIM = "org/ruboto/invoke/";
    static final String POLY = SHIM + "Poly";
    static final String MH = SHIM + "MethodHandle";
    static final String VH = SHIM + "VarHandle";
    static final String BACKPORTS = "org/ruboto/compat/Backports";

    static final Set<String> VH_ACCESS = Set.of(
            "get", "set", "getVolatile", "setVolatile", "getAcquire", "setRelease", "getOpaque", "setOpaque",
            "compareAndSet", "compareAndExchange", "compareAndExchangeAcquire", "compareAndExchangeRelease",
            "weakCompareAndSetPlain", "weakCompareAndSet", "weakCompareAndSetAcquire", "weakCompareAndSetRelease",
            "getAndSet", "getAndSetAcquire", "getAndSetRelease", "getAndAdd", "getAndAddAcquire", "getAndAddRelease",
            "getAndBitwiseOr", "getAndBitwiseOrRelease", "getAndBitwiseOrAcquire",
            "getAndBitwiseAnd", "getAndBitwiseAndRelease", "getAndBitwiseAndAcquire",
            "getAndBitwiseXor", "getAndBitwiseXorRelease", "getAndBitwiseXorAcquire");

    /** owner.name+desc of instance methods to retarget to Backports.name(owner, args...). */
    static final Set<String> BACKPORTED_METHODS = Set.of(
            "java/lang/reflect/Method.isDefault()Z",
            "java/lang/reflect/Constructor.getParameterCount()I",
            "java/util/concurrent/atomic/AtomicReferenceFieldUpdater.updateAndGet(Ljava/lang/Object;Ljava/util/function/UnaryOperator;)Ljava/lang/Object;",
            "java/util/jar/JarEntry.getLastModifiedTime()Ljava/nio/file/attribute/FileTime;",
            "java/util/jar/JarEntry.getLastAccessTime()Ljava/nio/file/attribute/FileTime;",
            "java/util/jar/JarEntry.getCreationTime()Ljava/nio/file/attribute/FileTime;",
            "java/util/logging/Logger.finest(Ljava/util/function/Supplier;)V",
            "java/math/BigInteger.longValueExact()J",
            "java/io/InputStream.readAllBytes()[B",
            "java/io/InputStream.readNBytes(I)[B",
            "java/io/InputStream.readNBytes([BII)I",
            "java/io/InputStream.skipNBytes(J)V",
            "java/lang/StringBuilder.isEmpty()Z",
            "java/lang/Thread.threadId()J",
            "java/nio/ByteBuffer.get(I[B)Ljava/nio/ByteBuffer;",
            "java/nio/ByteBuffer.get(I[BII)Ljava/nio/ByteBuffer;",
            "java/nio/ByteBuffer.put(I[B)Ljava/nio/ByteBuffer;",
            "java/nio/ByteBuffer.put(I[BII)Ljava/nio/ByteBuffer;",
            "java/nio/ByteBuffer.put(ILjava/nio/ByteBuffer;II)Ljava/nio/ByteBuffer;");

    /** owner.name of static fields to replace with a Backports getter. */
    static final Map<String, String> BACKPORTED_FIELDS = Map.of(
            "java/math/BigInteger.TWO", "bigIntegerTwo");

    static final Remapper REMAPPER = new Remapper(Opcodes.ASM9) {
        @Override
        public String map(String internalName) {
            if (internalName.startsWith("java/lang/invoke/")) return SHIM + internalName.substring("java/lang/invoke/".length());
            if (internalName.equals("java/lang/ClassValue")) return "org/ruboto/compat/ClassValue";
            return internalName;
        }
    };

    /** Superclass and interfaces, and declared methods (name + desc), of the classes being patched. */
    static final Map<String, List<String>> treeSupers = new HashMap<>();
    static final Map<String, Set<String>> treeMethods = new HashMap<>();

    /** call-site key ("mh" + desc or "vh:" + name + desc) to bridge method name. */
    static final Map<String, String> bridges = new LinkedHashMap<>();
    static final Map<String, Integer> counts = new HashMap<>();

    public static void main(String[] args) throws IOException {
        Path root = Paths.get(args[0]);
        readHierarchy(root);
        final int[] patched = {0};
        try (Stream<Path> paths = Files.walk(root)) {
            paths.filter(p -> p.toString().endsWith(".class"))
                    .filter(p -> {
                        String rel = root.relativize(p).toString().replace('\\', '/');
                        return !rel.startsWith("org/ruboto/invoke/") && !rel.startsWith("org/ruboto/compat/");
                    })
                    .forEach(p -> {
                        if (patch(p)) patched[0]++;
                    });
        }
        Path poly = root.resolve(POLY + ".class");
        Files.createDirectories(poly.getParent());
        Files.write(poly, generatePoly());
        System.out.println("Patched " + patched[0] + " classes for legacy Android: " + counts
                + ", " + bridges.size() + " polymorphic bridges");
    }

    static void readHierarchy(Path root) throws IOException {
        try (Stream<Path> paths = Files.walk(root)) {
            for (Path p : (Iterable<Path>) paths.filter(f -> f.toString().endsWith(".class"))::iterator) {
                new ClassReader(Files.readAllBytes(p)).accept(new ClassVisitor(Opcodes.ASM9) {
                    String name;

                    @Override
                    public void visit(int version, int access, String name, String sig, String superName, String[] interfaces) {
                        this.name = name;
                        List<String> supers = new ArrayList<>();
                        if (superName != null) supers.add(superName);
                        if (interfaces != null) supers.addAll(java.util.Arrays.asList(interfaces));
                        treeSupers.put(name, supers);
                        treeMethods.put(name, new HashSet<>());
                    }

                    @Override
                    public MethodVisitor visitMethod(int access, String mName, String desc, String sig, String[] ex) {
                        treeMethods.get(name).add(mName + desc);
                        return null;
                    }
                }, ClassReader.SKIP_CODE | ClassReader.SKIP_DEBUG | ClassReader.SKIP_FRAMES);
            }
        }
    }

    /**
     * The JDK class whose method a call to owner.nameDesc resolves to, if it
     * is one of BACKPORTED_METHODS; null if the class tree declares the
     * method itself on the way up.
     */
    static String backportedOwner(String owner, String nameDesc) {
        for (String key : BACKPORTED_METHODS) {
            int dot = key.indexOf('.');
            if (!key.substring(dot + 1).equals(nameDesc)) continue;
            String target = key.substring(0, dot);
            if (resolvesTo(owner, target, nameDesc, new HashSet<>())) return target;
        }
        return null;
    }

    static boolean resolvesTo(String owner, String target, String nameDesc, Set<String> seen) {
        if (owner.equals(target)) return true;
        if (!seen.add(owner)) return false;
        if (treeSupers.containsKey(owner)) {
            if (treeMethods.get(owner).contains(nameDesc)) return false;
            for (String sup : treeSupers.get(owner)) {
                if (resolvesTo(sup, target, nameDesc, seen)) return true;
            }
            return false;
        }
        try {
            ClassLoader loader = ClassLoader.getPlatformClassLoader();
            Class<?> ownerClass = Class.forName(owner.replace('/', '.'), false, loader);
            Class<?> targetClass = Class.forName(target.replace('/', '.'), false, loader);
            return targetClass.isAssignableFrom(ownerClass);
        } catch (ClassNotFoundException | LinkageError e) {
            return false;
        }
    }

    static boolean patch(Path path) {
        try {
            byte[] bytes = Files.readAllBytes(path);
            final boolean[] changed = {false};
            ClassReader reader = new ClassReader(bytes);
            ClassWriter writer = new ClassWriter(0);
            ClassVisitor rewriter = new ClassVisitor(Opcodes.ASM9, writer) {
                @Override
                public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] ex) {
                    return new CallRewriter(super.visitMethod(access, name, desc, sig, ex), changed);
                }
            };
            ClassRemapper remapper = new ClassRemapper(Opcodes.ASM9, rewriter, REMAPPER) {
                @Override
                protected MethodVisitor createMethodRemapper(MethodVisitor mv) {
                    return new MethodRemapper(Opcodes.ASM9, mv, remapper) {
                        @Override
                        public void visitInvokeDynamicInsn(String name, String desc, Handle bsm, Object... bsmArgs) {
                            // Keep the bootstrap method itself: d8 recognises and
                            // desugars the JDK bootstraps by their real names.
                            Object[] mapped = new Object[bsmArgs.length];
                            for (int i = 0; i < bsmArgs.length; i++) mapped[i] = remapper.mapValue(bsmArgs[i]);
                            mv.visitInvokeDynamicInsn(name, remapper.mapMethodDesc(desc), bsm, mapped);
                        }
                    };
                }
            };
            reader.accept(remapper, 0);
            byte[] out = writer.toByteArray();
            if (changed[0] || !java.util.Arrays.equals(out, bytes) && references(bytes)) {
                Files.write(path, out);
                return true;
            }
            return false;
        } catch (Throwable t) {
            System.err.println("Skipping " + path + ": " + t);
            return false;
        }
    }

    /** Whether the class constant pool mentions anything we relocate. */
    static boolean references(byte[] bytes) {
        String s = new String(bytes, java.nio.charset.StandardCharsets.ISO_8859_1);
        return s.contains("java/lang/invoke/") || s.contains("java/lang/ClassValue");
    }

    static void count(String what) {
        counts.merge(what, 1, Integer::sum);
    }

    static class CallRewriter extends MethodVisitor {
        private final boolean[] changed;

        CallRewriter(MethodVisitor mv, boolean[] changed) {
            super(Opcodes.ASM9, mv);
            this.changed = changed;
        }

        @Override
        public void visitMethodInsn(int op, String owner, String name, String desc, boolean itf) {
            String target;
            if (op == Opcodes.INVOKEVIRTUAL && owner.equals(MH) && (name.equals("invoke") || name.equals("invokeExact"))) {
                String bridge = bridge("mh" + desc);
                super.visitMethodInsn(Opcodes.INVOKESTATIC, POLY, bridge, prepend(MH, desc), false);
                changed[0] = true;
                count("MethodHandle.invoke");
            } else if (op == Opcodes.INVOKEVIRTUAL && owner.equals(VH) && VH_ACCESS.contains(name)) {
                String bridge = bridge("vh:" + name + desc);
                super.visitMethodInsn(Opcodes.INVOKESTATIC, POLY, bridge, prepend(VH, desc), false);
                changed[0] = true;
                count("VarHandle." + name);
            } else if (op == Opcodes.INVOKESTATIC && name.equals("registerAsParallelCapable") && desc.equals("()Z")) {
                // ClassLoader.registerAsParallelCapable (API 24), usually called
                // through a JRuby subclass.  Android class loaders are always
                // parallel capable, so it is just `true`.
                super.visitInsn(Opcodes.ICONST_1);
                changed[0] = true;
                count("ClassLoader.registerAsParallelCapable");
            } else if ((op == Opcodes.INVOKEVIRTUAL || op == Opcodes.INVOKESPECIAL)
                    && (target = backportedOwner(owner, name + desc)) != null) {
                super.visitMethodInsn(Opcodes.INVOKESTATIC, BACKPORTS, name, prepend(target, desc), false);
                changed[0] = true;
                count(target.substring(target.lastIndexOf('/') + 1) + "." + name);
            } else {
                super.visitMethodInsn(op, owner, name, desc, itf);
            }
        }

        @Override
        public void visitFieldInsn(int op, String owner, String name, String desc) {
            String getter = op == Opcodes.GETSTATIC ? BACKPORTED_FIELDS.get(owner + "." + name) : null;
            if (getter != null) {
                super.visitMethodInsn(Opcodes.INVOKESTATIC, BACKPORTS, getter, "()" + desc, false);
                changed[0] = true;
                count(owner.substring(owner.lastIndexOf('/') + 1) + "." + name);
            } else {
                super.visitFieldInsn(op, owner, name, desc);
            }
        }
    }

    static String prepend(String owner, String desc) {
        return "(L" + owner + ";" + desc.substring(1);
    }

    static synchronized String bridge(String key) {
        return bridges.computeIfAbsent(key, k -> (k.startsWith("mh") ? "mh" : "vh") + bridges.size());
    }

    // ------------------------------------------------------------------ Poly

    static byte[] generatePoly() {
        ClassWriter cw = new ClassWriter(ClassWriter.COMPUTE_MAXS);
        cw.visit(Opcodes.V1_8, Opcodes.ACC_PUBLIC | Opcodes.ACC_FINAL | Opcodes.ACC_SUPER, POLY, null, "java/lang/Object", null);
        for (Map.Entry<String, String> e : bridges.entrySet()) {
            String key = e.getKey();
            boolean isMh = key.startsWith("mh");
            String accessName = isMh ? null : key.substring(3, key.indexOf('('));
            String desc = key.substring(key.indexOf('('));
            String owner = isMh ? MH : VH;
            MethodVisitor mv = cw.visitMethod(Opcodes.ACC_PUBLIC | Opcodes.ACC_STATIC, e.getValue(), prepend(owner, desc), null, null);
            mv.visitCode();
            Type[] argTypes = Type.getArgumentTypes(desc);
            Type ret = Type.getReturnType(desc);
            if (!isMh && accessName.equals("get") && desc.equals("([BI)J")) {
                // Hot path (String hashing/scanning): no boxing.
                mv.visitVarInsn(Opcodes.ALOAD, 0);
                mv.visitVarInsn(Opcodes.ALOAD, 1);
                mv.visitVarInsn(Opcodes.ILOAD, 2);
                mv.visitMethodInsn(Opcodes.INVOKEVIRTUAL, VH, "getLongFromBytes", "([BI)J", false);
                mv.visitInsn(Opcodes.LRETURN);
            } else {
                mv.visitVarInsn(Opcodes.ALOAD, 0);
                if (!isMh) mv.visitLdcInsn(accessName);
                pushInt(mv, argTypes.length);
                mv.visitTypeInsn(Opcodes.ANEWARRAY, "java/lang/Object");
                int local = 1;
                for (int i = 0; i < argTypes.length; i++) {
                    mv.visitInsn(Opcodes.DUP);
                    pushInt(mv, i);
                    mv.visitVarInsn(argTypes[i].getOpcode(Opcodes.ILOAD), local);
                    box(mv, argTypes[i]);
                    mv.visitInsn(Opcodes.AASTORE);
                    local += argTypes[i].getSize();
                }
                if (isMh) {
                    mv.visitMethodInsn(Opcodes.INVOKEVIRTUAL, MH, "invokeArgs", "([Ljava/lang/Object;)Ljava/lang/Object;", false);
                } else {
                    mv.visitMethodInsn(Opcodes.INVOKEVIRTUAL, VH, "access", "(Ljava/lang/String;[Ljava/lang/Object;)Ljava/lang/Object;", false);
                }
                unboxAndReturn(mv, ret);
            }
            mv.visitMaxs(0, 0);
            mv.visitEnd();
        }
        cw.visitEnd();
        return cw.toByteArray();
    }

    static void pushInt(MethodVisitor mv, int i) {
        if (i <= 5) mv.visitInsn(Opcodes.ICONST_0 + i);
        else if (i <= Byte.MAX_VALUE) mv.visitIntInsn(Opcodes.BIPUSH, i);
        else mv.visitIntInsn(Opcodes.SIPUSH, i);
    }

    static void box(MethodVisitor mv, Type t) {
        String wrapper = wrapper(t);
        if (wrapper == null) return;
        mv.visitMethodInsn(Opcodes.INVOKESTATIC, wrapper, "valueOf", "(" + t.getDescriptor() + ")L" + wrapper + ";", false);
    }

    static void unboxAndReturn(MethodVisitor mv, Type t) {
        switch (t.getSort()) {
            case Type.VOID:
                mv.visitInsn(Opcodes.POP);
                mv.visitInsn(Opcodes.RETURN);
                return;
            case Type.BOOLEAN:
                mv.visitTypeInsn(Opcodes.CHECKCAST, "java/lang/Boolean");
                mv.visitMethodInsn(Opcodes.INVOKEVIRTUAL, "java/lang/Boolean", "booleanValue", "()Z", false);
                break;
            case Type.CHAR:
                mv.visitTypeInsn(Opcodes.CHECKCAST, "java/lang/Character");
                mv.visitMethodInsn(Opcodes.INVOKEVIRTUAL, "java/lang/Character", "charValue", "()C", false);
                break;
            case Type.BYTE: case Type.SHORT: case Type.INT: case Type.LONG: case Type.FLOAT: case Type.DOUBLE:
                mv.visitTypeInsn(Opcodes.CHECKCAST, "java/lang/Number");
                mv.visitMethodInsn(Opcodes.INVOKEVIRTUAL, "java/lang/Number", t.getClassName() + "Value", "()" + t.getDescriptor(), false);
                break;
            default:
                if (!t.getInternalName().equals("java/lang/Object")) mv.visitTypeInsn(Opcodes.CHECKCAST, t.getInternalName());
        }
        mv.visitInsn(t.getOpcode(Opcodes.IRETURN));
    }

    static String wrapper(Type t) {
        switch (t.getSort()) {
            case Type.BOOLEAN: return "java/lang/Boolean";
            case Type.CHAR: return "java/lang/Character";
            case Type.BYTE: return "java/lang/Byte";
            case Type.SHORT: return "java/lang/Short";
            case Type.INT: return "java/lang/Integer";
            case Type.LONG: return "java/lang/Long";
            case Type.FLOAT: return "java/lang/Float";
            case Type.DOUBLE: return "java/lang/Double";
            default: return null;
        }
    }
}
