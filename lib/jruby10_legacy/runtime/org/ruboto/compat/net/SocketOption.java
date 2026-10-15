package org.ruboto.compat.net;

/** Stand-in for java.net.SocketOption (API 24) in JRuby's socket library. */
public interface SocketOption<T> {
    String name();

    Class<T> type();
}
