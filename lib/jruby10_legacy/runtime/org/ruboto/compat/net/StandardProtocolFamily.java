package org.ruboto.compat.net;

/** Stand-in for java.net.StandardProtocolFamily (API 24) in JRuby's socket library. */
public enum StandardProtocolFamily implements ProtocolFamily {
    INET, INET6, UNIX
}
