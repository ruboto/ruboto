package org.ruboto.compat;

import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.math.BigInteger;
import java.nio.ByteBuffer;
import java.nio.file.attribute.FileTime;
import java.util.Arrays;
import java.util.concurrent.atomic.AtomicReferenceFieldUpdater;
import java.util.function.Supplier;
import java.util.function.UnaryOperator;
import java.util.jar.JarEntry;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Replacements for Java APIs that jruby-core calls but older Android
 * versions lack and d8 does not backport.  LegacyAndroidPatcher retargets
 * the calls here; each method takes the original receiver first.
 */
public final class Backports {
    private Backports() {}

    // java.lang.reflect.Method#isDefault (API 24)
    public static boolean isDefault(Method m) {
        return (m.getModifiers() & (Modifier.ABSTRACT | Modifier.PUBLIC | Modifier.STATIC)) == Modifier.PUBLIC
                && m.getDeclaringClass().isInterface();
    }

    // java.lang.reflect.Constructor#getParameterCount (API 26)
    public static int getParameterCount(Constructor<?> c) {
        return c.getParameterTypes().length;
    }

    // java.util.concurrent.atomic.AtomicReferenceFieldUpdater#updateAndGet (API 24)
    @SuppressWarnings({"unchecked", "rawtypes"})
    public static Object updateAndGet(AtomicReferenceFieldUpdater updater, Object obj, UnaryOperator op) {
        Object prev, next;
        do {
            prev = updater.get(obj);
            next = op.apply(prev);
        } while (!updater.compareAndSet(obj, prev, next));
        return next;
    }

    // java.util.jar.JarEntry time accessors (API 26)
    public static FileTime getLastModifiedTime(JarEntry e) {
        long t = e.getTime();
        return t == -1 ? null : FileTime.fromMillis(t);
    }

    public static FileTime getLastAccessTime(JarEntry e) {
        return null;
    }

    public static FileTime getCreationTime(JarEntry e) {
        return null;
    }

    // java.util.logging.Logger#finest(Supplier) (API 26)
    public static void finest(Logger logger, Supplier<String> message) {
        if (logger.isLoggable(Level.FINEST)) logger.finest(message.get());
    }

    // java.math.BigInteger#longValueExact (API 31)
    public static long longValueExact(BigInteger b) {
        if (b.bitLength() > 63) throw new ArithmeticException("BigInteger out of long range");
        return b.longValue();
    }

    // java.math.BigInteger.TWO (API 33)
    public static BigInteger bigIntegerTwo() {
        return BigInteger.valueOf(2);
    }

    // java.io.InputStream#readAllBytes (API 33)
    public static byte[] readAllBytes(InputStream in) throws IOException {
        return readNBytes(in, Integer.MAX_VALUE);
    }

    // java.io.InputStream#readNBytes(int) (API 33)
    public static byte[] readNBytes(InputStream in, int len) throws IOException {
        if (len < 0) throw new IllegalArgumentException("len < 0");
        byte[] buf = new byte[Math.min(len, 8192)];
        int total = 0;
        while (total < len) {
            if (total == buf.length) buf = Arrays.copyOf(buf, (int) Math.min((long) len, Math.max(buf.length * 2L, 8192L)));
            int n = in.read(buf, total, Math.min(buf.length, len) - total);
            if (n < 0) break;
            total += n;
        }
        return total == buf.length ? buf : Arrays.copyOf(buf, total);
    }

    // java.io.InputStream#readNBytes(byte[], int, int) (API 33)
    public static int readNBytes(InputStream in, byte[] b, int off, int len) throws IOException {
        int n = 0;
        while (n < len) {
            int count = in.read(b, off + n, len - n);
            if (count < 0) break;
            n += count;
        }
        return n;
    }

    // java.io.InputStream#skipNBytes (API 34)
    public static void skipNBytes(InputStream in, long n) throws IOException {
        while (n > 0) {
            long skipped = in.skip(n);
            if (skipped > 0) {
                n -= skipped;
            } else if (in.read() == -1) {
                throw new java.io.EOFException();
            } else {
                n--;
            }
        }
    }

    // java.lang.StringBuilder#isEmpty (API 35)
    public static boolean isEmpty(StringBuilder sb) {
        return sb.length() == 0;
    }

    // java.lang.Thread#threadId (API 36)
    public static long threadId(Thread t) {
        return t.getId();
    }

    // java.nio.ByteBuffer absolute bulk get/put (API 35)
    public static ByteBuffer get(ByteBuffer bb, int index, byte[] dst) {
        return get(bb, index, dst, 0, dst.length);
    }

    public static ByteBuffer get(ByteBuffer bb, int index, byte[] dst, int offset, int length) {
        checkRange(bb, index, length);
        for (int i = 0; i < length; i++) dst[offset + i] = bb.get(index + i);
        return bb;
    }

    public static ByteBuffer put(ByteBuffer bb, int index, byte[] src) {
        return put(bb, index, src, 0, src.length);
    }

    public static ByteBuffer put(ByteBuffer bb, int index, byte[] src, int offset, int length) {
        checkRange(bb, index, length);
        // Copy first: src may be the buffer's own backing array.
        byte[] copy = Arrays.copyOfRange(src, offset, offset + length);
        for (int i = 0; i < length; i++) bb.put(index + i, copy[i]);
        return bb;
    }

    public static ByteBuffer put(ByteBuffer bb, int index, ByteBuffer src, int offset, int length) {
        checkRange(bb, index, length);
        checkRange(src, offset, length);
        // Copy first: src may be bb itself (overlapping IO::Buffer#copy).
        byte[] copy = new byte[length];
        for (int i = 0; i < length; i++) copy[i] = src.get(offset + i);
        for (int i = 0; i < length; i++) bb.put(index + i, copy[i]);
        return bb;
    }

    private static void checkRange(ByteBuffer bb, int index, int length) {
        if (index < 0 || length < 0 || index > bb.limit() - length) {
            throw new IndexOutOfBoundsException("index " + index + ", length " + length + ", limit " + bb.limit());
        }
    }

    // java.nio.channels.SocketChannel#getRemoteAddress (API 24)
    public static java.net.SocketAddress getRemoteAddress(java.nio.channels.SocketChannel channel) throws IOException {
        if (!channel.isOpen()) throw new java.nio.channels.ClosedChannelException();
        return channel.socket().getRemoteSocketAddress();
    }

    // java.nio.channels.DatagramChannel#open(ProtocolFamily) (API 24).  The
    // family only matters for the address the socket is bound to.
    public static java.nio.channels.DatagramChannel open(org.ruboto.compat.net.ProtocolFamily family) throws IOException {
        return java.nio.channels.DatagramChannel.open();
    }

    // java.nio.channels.DatagramChannel#bind (API 24)
    public static java.nio.channels.DatagramChannel bind(java.nio.channels.DatagramChannel channel, java.net.SocketAddress local) throws IOException {
        if (!channel.isOpen()) throw new java.nio.channels.ClosedChannelException();
        if (channel.socket().isBound()) throw new java.nio.channels.AlreadyBoundException();
        channel.socket().bind(local);
        return channel;
    }

    // java.nio.channels.DatagramChannel#getLocalAddress (API 24)
    public static java.net.SocketAddress getLocalAddress(java.nio.channels.DatagramChannel channel) throws IOException {
        if (!channel.isOpen()) throw new java.nio.channels.ClosedChannelException();
        return channel.socket().getLocalSocketAddress();
    }

    // java.nio.channels.SocketChannel#bind (API 24)
    public static java.nio.channels.SocketChannel bind(java.nio.channels.SocketChannel channel, java.net.SocketAddress local) throws IOException {
        if (!channel.isOpen()) throw new java.nio.channels.ClosedChannelException();
        if (channel.socket().isBound()) throw new java.nio.channels.AlreadyBoundException();
        channel.socket().bind(local);
        return channel;
    }

    // java.nio.channels.SocketChannel#setOption (API 24), with the options of
    // org.ruboto.compat.net.StandardSocketOptions.
    public static java.nio.channels.SocketChannel setOption(java.nio.channels.SocketChannel channel,
                                                            org.ruboto.compat.net.SocketOption<?> option, Object value) throws IOException {
        java.net.Socket socket = channel.socket();
        switch (option.name()) {
            case "SO_REUSEADDR": socket.setReuseAddress((Boolean) value); break;
            case "SO_KEEPALIVE": socket.setKeepAlive((Boolean) value); break;
            case "TCP_NODELAY": socket.setTcpNoDelay((Boolean) value); break;
            case "SO_SNDBUF": socket.setSendBufferSize((Integer) value); break;
            case "SO_RCVBUF": socket.setReceiveBufferSize((Integer) value); break;
            case "SO_LINGER": {
                int seconds = (Integer) value;
                socket.setSoLinger(seconds >= 0, Math.max(seconds, 0));
                break;
            }
            case "IP_TOS": socket.setTrafficClass((Integer) value); break;
            default: throw new UnsupportedOperationException("'" + option.name() + "' not supported");
        }
        return channel;
    }

    // java.nio.channels.SocketChannel#shutdownOutput (API 24)
    public static java.nio.channels.SocketChannel shutdownOutput(java.nio.channels.SocketChannel channel) throws IOException {
        channel.socket().shutdownOutput();
        return channel;
    }
}
