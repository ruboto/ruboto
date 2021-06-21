//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by Fernflower decompiler)
//

package sun.misc;

final class NativeSignalHandler implements SignalHandler {
    private final long handler;

    long getHandler() {
        return this.handler;
    }

    NativeSignalHandler(long var1) {
        this.handler = var1;
    }

    public void handle(Signal var1) {
        handle0(var1.getNumber(), this.handler);
    }

    private static native void handle0(int var0, long var1);
}
