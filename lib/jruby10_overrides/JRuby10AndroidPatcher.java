import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.stream.Stream;

import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.ClassWriter;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;
import org.objectweb.asm.Type;

/**
 * Rewrites JVM-only API calls in a tree of .class files to Android-safe
 * equivalents.
 *
 * java.lang.Module does not exist on ART:
 *
 *   Class.getModule()      becomes  POP; ACONST_NULL   (module = null)
 *   Module.canRead(Module) becomes  POP2; ICONST_1     (always readable)
 *   ClassLoader.getUnnamedModule() becomes  POP; ACONST_NULL
 *   any other Module method pops its arguments and receiver and pushes
 *   null/false/0 (e.g. isNamed() is false, so addReads is skipped)
 *
 * Android's java.nio buffers lack the Java 9+ covariant overrides
 * (ByteBuffer.limit(int) returns Buffer, not ByteBuffer), and
 * ConcurrentHashMap.keySet() returns Set, not KeySetView.  Calls compiled
 * against the JDK signatures are retargeted to the superclass signature
 * followed by a checkcast, which works on both the JVM (bridge methods)
 * and ART.
 *
 * com.sun.nio.file.ExtendedOpenOption has no fields on Android; reads
 * become null, which JRuby's ModeFlags null-guards.
 *
 * Java interface implementation without runtime class generation
 * (Ruboto runs with jruby.interfaces.useProxy=true):
 *
 *   RubyProc.toJava: GETSTATIC Block$Type.JAVA becomes ACONST_NULL, so a
 *   block passed to a Java method is converted like any other proc
 *   (defaultToJava -> JavaUtil.convertProcToInterface -> java.lang.reflect.Proxy)
 *   instead of defining org.jruby.gen.BlockInterfaceImpl$... at runtime
 *   (JRuby 10.1's BlockInterfaceGenerator ignores jruby.interfaces.useProxy).
 *
 *   JavaInterfaceTemplate.initInterfaceImplMethods: RubyClass.getAllocator()
 *   becomes RubotoInterfaceAllocator.baseAllocator(RubyClass), which never
 *   returns null (Interface.impl {} NPE) or a self-delegating allocator
 *   (StackOverflowError for named classes that include an interface).
 *
 * All rewrites preserve the stack shape, so existing stack map frames
 * remain valid.
 */
public class JRuby10AndroidPatcher {
    static final java.util.Set<String> BUFFER_OWNERS = java.util.Set.of(
            "java/nio/Buffer", "java/nio/ByteBuffer", "java/nio/CharBuffer",
            "java/nio/ShortBuffer", "java/nio/IntBuffer", "java/nio/LongBuffer",
            "java/nio/FloatBuffer", "java/nio/DoubleBuffer", "java/nio/MappedByteBuffer");
    static final java.util.Set<String> BUFFER_METHODS = java.util.Set.of(
            "clear", "flip", "limit", "mark", "position", "reset", "rewind");
    public static void main(String[] args) throws IOException {
        Path root = Paths.get(args[0]);
        final int[] patched = {0};
        try (Stream<Path> paths = Files.walk(root)) {
            paths.filter(p -> p.toString().endsWith(".class"))
                    // backport9 detects java.lang.Module at runtime and has its
                    // own fallback for platforms without it, so leave it alone.
                    .filter(p -> !root.relativize(p).toString().replace('\\', '/').startsWith("com/headius/backport9/"))
                    .forEach(p -> {
                        if (patch(p)) patched[0]++;
                    });
        }
        System.out.println("Patched " + patched[0] + " classes for Android");
    }

    static boolean patch(Path path) {
        try {
            byte[] bytes = Files.readAllBytes(path);
            final boolean[] changed = {false};
            ClassReader reader = new ClassReader(bytes);
            ClassWriter writer = new ClassWriter(0);
            final String className = reader.getClassName();
            reader.accept(new ClassVisitor(Opcodes.ASM9, writer) {
                @Override
                public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] ex) {
                    MethodVisitor mv = super.visitMethod(access, name, desc, sig, ex);
                    final boolean procToJava = className.equals("org/jruby/RubyProc")
                            && name.equals("toJava") && desc.equals("(Ljava/lang/Class;)Ljava/lang/Object;");
                    final boolean interfaceImplMethods = className.equals("org/jruby/java/proxies/JavaInterfaceTemplate")
                            && name.equals("initInterfaceImplMethods");
                    return new MethodVisitor(Opcodes.ASM9, mv) {
                        @Override
                        public void visitMethodInsn(int op, String owner, String mName, String mDesc, boolean itf) {
                            if (interfaceImplMethods && op == Opcodes.INVOKEVIRTUAL
                                    && owner.equals("org/jruby/RubyClass") && mName.equals("getAllocator")
                                    && mDesc.equals("()Lorg/jruby/runtime/ObjectAllocator;")) {
                                super.visitMethodInsn(Opcodes.INVOKESTATIC,
                                        "org/jruby/java/proxies/RubotoInterfaceAllocator", "baseAllocator",
                                        "(Lorg/jruby/RubyClass;)Lorg/jruby/runtime/ObjectAllocator;", false);
                                changed[0] = true;
                            } else if (owner.equals("java/lang/Class") && mName.equals("getModule")
                                    && mDesc.equals("()Ljava/lang/Module;")) {
                                super.visitInsn(Opcodes.POP);
                                super.visitInsn(Opcodes.ACONST_NULL);
                                changed[0] = true;
                            } else if (owner.equals("java/lang/Module") && mName.equals("canRead")
                                    && mDesc.equals("(Ljava/lang/Module;)Z")) {
                                super.visitInsn(Opcodes.POP2);
                                super.visitInsn(Opcodes.ICONST_1);
                                changed[0] = true;
                            } else if (owner.equals("java/lang/ClassLoader") && mName.equals("getUnnamedModule")
                                    && mDesc.equals("()Ljava/lang/Module;")) {
                                super.visitInsn(Opcodes.POP);
                                super.visitInsn(Opcodes.ACONST_NULL);
                                changed[0] = true;
                            } else if (op == Opcodes.INVOKEVIRTUAL && owner.equals("java/lang/Module")) {
                                Type[] argTypes = Type.getArgumentTypes(mDesc);
                                for (int i = argTypes.length - 1; i >= 0; i--) {
                                    super.visitInsn(argTypes[i].getSize() == 2 ? Opcodes.POP2 : Opcodes.POP);
                                }
                                super.visitInsn(Opcodes.POP);
                                pushDefault(Type.getReturnType(mDesc));
                                changed[0] = true;
                            } else if (op == Opcodes.INVOKEVIRTUAL && BUFFER_OWNERS.contains(owner)
                                    && BUFFER_METHODS.contains(mName)
                                    && mDesc.endsWith(")L" + owner + ";")) {
                                String baseDesc = mDesc.substring(0, mDesc.lastIndexOf(')') + 1) + "Ljava/nio/Buffer;";
                                super.visitMethodInsn(op, owner, mName, baseDesc, itf);
                                super.visitTypeInsn(Opcodes.CHECKCAST, owner);
                                changed[0] = true;
                            } else if (op == Opcodes.INVOKEVIRTUAL
                                    && owner.equals("java/util/concurrent/ConcurrentHashMap")
                                    && mName.equals("keySet")
                                    && mDesc.equals("()Ljava/util/concurrent/ConcurrentHashMap$KeySetView;")) {
                                super.visitMethodInsn(op, owner, mName, "()Ljava/util/Set;", itf);
                                super.visitTypeInsn(Opcodes.CHECKCAST, "java/util/concurrent/ConcurrentHashMap$KeySetView");
                                changed[0] = true;
                            } else {
                                super.visitMethodInsn(op, owner, mName, mDesc, itf);
                            }
                        }

                        private void pushDefault(Type t) {
                            switch (t.getSort()) {
                                case Type.VOID: break;
                                case Type.LONG: super.visitInsn(Opcodes.LCONST_0); break;
                                case Type.FLOAT: super.visitInsn(Opcodes.FCONST_0); break;
                                case Type.DOUBLE: super.visitInsn(Opcodes.DCONST_0); break;
                                case Type.OBJECT: case Type.ARRAY: super.visitInsn(Opcodes.ACONST_NULL); break;
                                default: super.visitInsn(Opcodes.ICONST_0);
                            }
                        }

                        @Override
                        public void visitFieldInsn(int op, String owner, String fName, String fDesc) {
                            if (procToJava && op == Opcodes.GETSTATIC
                                    && owner.equals("org/jruby/runtime/Block$Type") && fName.equals("JAVA")) {
                                super.visitInsn(Opcodes.ACONST_NULL);
                                changed[0] = true;
                            } else if (op == Opcodes.GETSTATIC && owner.equals("com/sun/nio/file/ExtendedOpenOption")) {
                                super.visitInsn(Opcodes.ACONST_NULL);
                                changed[0] = true;
                            } else {
                                super.visitFieldInsn(op, owner, fName, fDesc);
                            }
                        }
                    };
                }
            }, 0);
            if (changed[0]) {
                Files.write(path, writer.toByteArray());
                return true;
            }
            return false;
        } catch (Throwable t) {
            System.err.println("Skipping " + path + ": " + t);
            return false;
        }
    }
}
