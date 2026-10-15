package org.ruboto.compat.net;

/**
 * Stand-in for java.net.StandardSocketOptions (API 24) in JRuby's socket
 * library; org.ruboto.compat.Backports applies them to the channel's socket.
 */
public final class StandardSocketOptions {
    private StandardSocketOptions() {}

    public static final SocketOption<Boolean> SO_BROADCAST = option("SO_BROADCAST", Boolean.class);
    public static final SocketOption<Boolean> SO_KEEPALIVE = option("SO_KEEPALIVE", Boolean.class);
    public static final SocketOption<Integer> SO_SNDBUF = option("SO_SNDBUF", Integer.class);
    public static final SocketOption<Integer> SO_RCVBUF = option("SO_RCVBUF", Integer.class);
    public static final SocketOption<Boolean> SO_REUSEADDR = option("SO_REUSEADDR", Boolean.class);
    public static final SocketOption<Integer> SO_LINGER = option("SO_LINGER", Integer.class);
    public static final SocketOption<Integer> IP_TOS = option("IP_TOS", Integer.class);
    public static final SocketOption<Boolean> TCP_NODELAY = option("TCP_NODELAY", Boolean.class);

    private static <T> SocketOption<T> option(final String name, final Class<T> type) {
        return new SocketOption<T>() {
            public String name() { return name; }

            public Class<T> type() { return type; }

            @Override
            public String toString() { return name; }
        };
    }
}
