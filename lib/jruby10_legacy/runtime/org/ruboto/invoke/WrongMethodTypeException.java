package org.ruboto.invoke;

/** Stand-in for java.lang.invoke.WrongMethodTypeException. */
public class WrongMethodTypeException extends RuntimeException {
    public WrongMethodTypeException() {
        super();
    }

    public WrongMethodTypeException(String message) {
        super(message);
    }
}
