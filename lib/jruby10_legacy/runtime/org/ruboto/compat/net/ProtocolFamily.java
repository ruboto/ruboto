package org.ruboto.compat.net;

/** Stand-in for java.net.ProtocolFamily (API 24) in JRuby's socket library. */
public interface ProtocolFamily {
    String name();
}
