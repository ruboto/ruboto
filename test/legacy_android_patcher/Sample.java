import java.io.ByteArrayInputStream;
import java.lang.invoke.MethodHandle;
import java.lang.invoke.MethodHandles;
import java.lang.invoke.MethodType;
import java.lang.invoke.VarHandle;
import java.math.BigInteger;
import java.nio.ByteOrder;

public class Sample {
    volatile Object ref;
    volatile int count;
    byte flag;
    static final VarHandle REF, COUNT, FLAG, LONGS;
    static {
        try {
            MethodHandles.Lookup lookup = MethodHandles.lookup();
            REF = lookup.findVarHandle(Sample.class, "ref", Object.class);
            COUNT = lookup.findVarHandle(Sample.class, "count", int.class);
            FLAG = lookup.findVarHandle(Sample.class, "flag", byte.class);
            LONGS = MethodHandles.byteArrayViewVarHandle(long[].class, ByteOrder.LITTLE_ENDIAN);
        } catch (ReflectiveOperationException e) {
            throw new ExceptionInInitializerError(e);
        }
    }

    static String greet(String name, int n) { return name + n; }

    public static void main(String[] args) throws Throwable {
        MethodHandle greet = MethodHandles.lookup().findStatic(Sample.class, "greet",
                MethodType.methodType(String.class, String.class, int.class));
        String direct = (String) greet.invokeExact("x", 1);
        String bound = (String) MethodHandles.insertArguments(greet, 1, 2).invokeExact("y");
        MethodHandle length = MethodHandles.filterReturnValue(greet,
                MethodHandles.lookup().findVirtual(String.class, "length", MethodType.methodType(int.class)));
        int len = (int) length.invokeExact("abc", 42);
        Sample o = new Sample();
        boolean cas1 = REF.compareAndSet(o, (Object) null, (Object) "a");
        boolean cas2 = REF.compareAndSet(o, (Object) null, (Object) "b");
        int old = (int) COUNT.getAndAdd(o, 5);
        boolean flagged = FLAG.compareAndSet(o, (byte) 0, (byte) 1);
        long little = (long) LONGS.get(new byte[]{1, 2, 0, 0, 0, 0, 0, 0, 9}, 0);
        ClassValue<String> names = new ClassValue<String>() {
            protected String computeValue(Class<?> c) { return c.getSimpleName(); }
        };
        byte[] all = new ByteArrayInputStream("hello".getBytes()).readAllBytes();
        System.out.println(String.join(",", direct, bound, String.valueOf(len), String.valueOf(cas1),
                String.valueOf(cas2), (String) REF.getVolatile(o), String.valueOf(old), String.valueOf(o.count),
                String.valueOf(flagged), String.valueOf(o.flag), String.valueOf(little), names.get(Integer.class),
                new String(all), BigInteger.TWO.toString()));
        System.out.println(greet.getClass().getName());
    }
}
