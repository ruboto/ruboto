//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package sun.misc;

import java.util.Hashtable;

public final class Signal {
    private static Hashtable<Signal, SignalHandler> handlers = new Hashtable(4);
    private static Hashtable<Integer, Signal> signals = new Hashtable(4);
    private int number;
    private String name;

    public int getNumber() {
        return this.number;
    }

    public String getName() {
        return this.name;
    }

    public boolean equals(Object var1) {
        if (this == var1) {
            return true;
        } else if (var1 != null && var1 instanceof Signal) {
            Signal var2 = (Signal)var1;
            return this.name.equals(var2.name) && this.number == var2.number;
        } else {
            return false;
        }
    }

    public int hashCode() {
        return this.number;
    }

    public String toString() {
        return "SIG" + this.name;
    }

    public Signal(String var1) {
        this.number = findSignal(var1);
        this.name = var1;
        if (this.number < 0) {
            throw new IllegalArgumentException("Unknown signal: " + var1);
        }
    }

    public static synchronized SignalHandler handle(Signal var0, SignalHandler var1) throws IllegalArgumentException {
        long var2 = var1 instanceof NativeSignalHandler ? ((NativeSignalHandler)var1).getHandler() : 2L;
        long var4 = handle0(var0.number, var2);
        if (var4 == -1L) {
            throw new IllegalArgumentException("Signal already used by VM or OS: " + var0);
        } else {
            signals.put(var0.number, var0);
            synchronized(handlers) {
                SignalHandler var7 = (SignalHandler)handlers.get(var0);
                handlers.remove(var0);
                if (var2 == 2L) {
                    handlers.put(var0, var1);
                }

                if (var4 == 0L) {
                    return SignalHandler.SIG_DFL;
                } else if (var4 == 1L) {
                    return SignalHandler.SIG_IGN;
                } else {
                    return (SignalHandler)(var4 == 2L ? var7 : new NativeSignalHandler(var4));
                }
            }
        }
    }

    public static void raise(Signal var0) throws IllegalArgumentException {
        if (handlers.get(var0) == null) {
            throw new IllegalArgumentException("Unhandled signal: " + var0);
        } else {
            raise0(var0.number);
        }
    }

    private static void dispatch(int var0) {
        final Signal var1 = (Signal)signals.get(var0);
        final SignalHandler var2 = (SignalHandler)handlers.get(var1);
        Runnable var3 = new Runnable() {
            public void run() {
                var2.handle(var1);
            }
        };
        if (var2 != null) {
            (new Thread(var3, var1 + " handler")).start();
        }

    }

    private static native int findSignal(String var0);

    private static native long handle0(int var0, long var1);

    private static native void raise0(int var0);
}
