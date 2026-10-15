import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.Stream;

import org.objectweb.asm.AnnotationVisitor;
import org.objectweb.asm.ClassReader;
import org.objectweb.asm.ClassVisitor;
import org.objectweb.asm.MethodVisitor;
import org.objectweb.asm.Opcodes;

/**
 * Lists classes (dot-form, one per line on stdout) in a tree of .class files
 * that declare at least one @JRubyMethod(frame = true) method.  In
 * MethodHandles binding mode these are the only methods for which JRuby
 * generates invoker bytecode at runtime, which ART cannot load, so their
 * invokers are pregenerated at build time with org.jruby.anno.InvokerGenerator.
 */
public class FramedMethodLister {
    public static void main(String[] args) throws Exception {
        Path root = Paths.get(args[0]);
        final Set<String> classes = new TreeSet<>();
        try (Stream<Path> paths = Files.walk(root)) {
            paths.filter(p -> p.toString().endsWith(".class")).forEach(p -> {
                try {
                    ClassReader reader = new ClassReader(Files.readAllBytes(p));
                    final String[] className = {null};
                    reader.accept(new ClassVisitor(Opcodes.ASM9) {
                        @Override
                        public void visit(int version, int access, String name, String sig, String superName, String[] interfaces) {
                            className[0] = name;
                        }

                        @Override
                        public MethodVisitor visitMethod(int access, String name, String desc, String sig, String[] ex) {
                            return new MethodVisitor(Opcodes.ASM9) {
                                @Override
                                public AnnotationVisitor visitAnnotation(String annoDesc, boolean visible) {
                                    if (!"Lorg/jruby/anno/JRubyMethod;".equals(annoDesc)) return null;
                                    return new AnnotationVisitor(Opcodes.ASM9) {
                                        @Override
                                        public void visit(String name, Object value) {
                                            if ("frame".equals(name) && Boolean.TRUE.equals(value)) {
                                                classes.add(className[0].replace('/', '.'));
                                            }
                                        }
                                    };
                                }
                            };
                        }
                    }, ClassReader.SKIP_CODE | ClassReader.SKIP_FRAMES | ClassReader.SKIP_DEBUG);
                } catch (Throwable t) {
                    // not a readable class file; skip
                }
            });
        }
        for (String c : classes) System.out.println(c);
    }
}
