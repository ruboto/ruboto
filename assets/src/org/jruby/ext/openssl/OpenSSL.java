/*
 * The MIT License
 *
 * Copyright (c) 2014 Karol Bucek LTD.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */
package org.jruby.ext.openssl;

import java.security.NoSuchProviderException;
import java.util.Map;

import org.jruby.CompatVersion;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.jruby.util.SafePropertyAccessor;

/**
 * OpenSSL (methods as well as an entry point)
 *
 * @author kares
 */
@JRubyModule(name = "OpenSSL")
public final class OpenSSL {

    public static void load(final Ruby runtime) {
        System.out.println("CUSTOM OpenSSL load");
        createOpenSSL(runtime);
    }

    public static boolean isProviderAvailable() {
        System.out.println("CUSTOM OpenSSL isProviderAvailable");
        return SecurityHelper.isProviderAvailable("BC");
    }

    public static void createOpenSSL(final Ruby runtime) {
        System.out.println("CUSTOM OpenSSL createOpenSSL");
        boolean registerProvider = SafePropertyAccessor.getBoolean("jruby.openssl.provider.register");
        SecurityHelper.setRegisterProvider( registerProvider );

        System.out.println("OpenSSL createOpenSSL create module");
        final RubyModule _OpenSSL = runtime.getOrCreateModule("OpenSSL");
        System.out.println("OpenSSL createOpenSSL create OpenSSLError");
        RubyClass _StandardError = runtime.getClass("StandardError");
        _OpenSSL.defineClassUnder("OpenSSLError", _StandardError, _StandardError.getAllocator());
        System.out.println("OpenSSL createOpenSSL defineAnnotatedMethods");
        _OpenSSL.defineAnnotatedMethods(OpenSSL.class);

        // set OpenSSL debug internal flag early on so it can print traces even while loading extension
        System.out.println("OpenSSL createOpenSSL debug");
        setDebug(_OpenSSL, runtime.newBoolean( SafePropertyAccessor.getBoolean("jruby.openssl.debug") ) );

        System.out.println("OpenSSL createOpenSSL warn");
        final String warn = SafePropertyAccessor.getProperty("jruby.openssl.warn");
        if ( warn != null ) OpenSSL.warn = Boolean.parseBoolean(warn);

        System.out.println("OpenSSL createOpenSSL createPKey");
        PKey.createPKey(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createBN");
        BN.createBN(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createDigest");
        Digest.createDigest(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createCipher");
        Cipher.createCipher(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createRandom");
        Random.createRandom(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createHMAC");
        HMAC.createHMAC(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createConfig");
        Config.createConfig(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createASN1");
        ASN1.createASN1(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createX509");
        X509.createX509(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createNetscapeSPKI");
        NetscapeSPKI.createNetscapeSPKI(runtime, _OpenSSL);
        try {
        System.out.println("OpenSSL createOpenSSL createSSL");
        SSL.createSSL(runtime, _OpenSSL);
        } catch (Throwable e) {
            System.out.println("Got exception creating SSL:");
            e.printStackTrace();
        }
        System.out.println("OpenSSL createOpenSSL createPKCS7");
        PKCS7.createPKCS7(runtime, _OpenSSL);
        System.out.println("OpenSSL createOpenSSL createPKCS5");
        PKCS5.createPKCS5(runtime, _OpenSSL);

        System.out.println("OpenSSL createOpenSSL require version");
        runtime.getLoadService().require("jopenssl/version");

        // MRI 1.8.7 :
        // OpenSSL::VERSION: "1.0.0"
        // OpenSSL::OPENSSL_VERSION: "OpenSSL 1.0.1c 10 May 2012"
        // OpenSSL::OPENSSL_VERSION_NUMBER: 268439615
        // MRI 1.9.3 / 2.2.3 :
        // OpenSSL::VERSION: "1.1.0"
        // OpenSSL::OPENSSL_VERSION: "OpenSSL 1.0.1f 6 Jan 2014"
        // OpenSSL::OPENSSL_VERSION_NUMBER: 268439663
        // OpenSSL::OPENSSL_LIBRARY_VERSION: ""OpenSSL 1.0.2d 9 Jul 2015"
        // OpenSSL::FIPS: false

        System.out.println("OpenSSL createOpenSSL check version");
        final byte[] version = { '1','.','1','.','0' };
        final boolean ruby18 = runtime.getInstanceConfig().getCompatVersion() == CompatVersion.RUBY1_8;
        if ( ruby18 ) version[2] = '0'; // 1.0.0 compatible on 1.8

        System.out.println("OpenSSL createOpenSSL set version");
        _OpenSSL.setConstant("VERSION", StringHelper.newString(runtime, version));

        System.out.println("OpenSSL createOpenSSL get Jopenssl version");
        final RubyModule _Jopenssl = runtime.getModule("Jopenssl");
        final RubyModule _Version = (RubyModule) _Jopenssl.getConstantAt("Version");
        final RubyString jVERSION = _Version.getConstantAt("VERSION").asString();

        final byte[] JRuby_OpenSSL_ = { 'J','R','u','b','y','-','O','p','e','n','S','S','L',' ' };
        final int OPENSSL_VERSION_NUMBER = 999999999; // NOTE: smt more useful?

        ByteList OPENSSL_VERSION = new ByteList( jVERSION.getByteList().length() + JRuby_OpenSSL_.length );
        OPENSSL_VERSION.setEncoding( jVERSION.getEncoding() );
        OPENSSL_VERSION.append( JRuby_OpenSSL_ );
        OPENSSL_VERSION.append( jVERSION.getByteList() );

        final RubyString VERSION;
        _OpenSSL.setConstant("OPENSSL_VERSION", VERSION = runtime.newString(OPENSSL_VERSION));
        _OpenSSL.setConstant("OPENSSL_VERSION_NUMBER", runtime.newFixnum(OPENSSL_VERSION_NUMBER));
        if ( ! ruby18 ) {
            // MRI 2.3 tests do: /\AOpenSSL +0\./ !~ OpenSSL::OPENSSL_LIBRARY_VERSION
            _OpenSSL.setConstant("OPENSSL_LIBRARY_VERSION", VERSION);
            _OpenSSL.setConstant("OPENSSL_FIPS", runtime.getFalse());
        }
        System.out.println("OpenSSL createOpenSSL...OK");
    }

    static RubyClass _OpenSSLError(final Ruby runtime) {
        return runtime.getModule("OpenSSL").getClass("OpenSSLError");
    }

    // OpenSSL module methods :

    @JRubyMethod(name = "errors", meta = true)
    public static IRubyObject errors(IRubyObject self) {
        final Ruby runtime = self.getRuntime();
        RubyArray result = runtime.newArray();
        for (Map.Entry<Integer, String> e : X509.getErrors().entrySet()) {
            result.add( runtime.newString( e.getValue() ) );
        }
        return result;
    }

    @JRubyMethod(name = "debug", meta = true)
    public static IRubyObject getDebug(IRubyObject self) {
        return (IRubyObject) getDebug((RubyModule) self);
    }

    private static Object getDebug(RubyModule self) {
        return self.getInternalVariable("debug");
    }

    @JRubyMethod(name = "debug=", meta = true)
    public static IRubyObject setDebug(IRubyObject self, IRubyObject debug) {
        ((RubyModule) self).setInternalVariable("debug", debug);
        OpenSSL.debug = debug.isTrue();
        return debug;
    }

    @JRubyMethod(name = "Digest", meta = true)
    public static IRubyObject Digest(final IRubyObject self, final IRubyObject name) {
        // OpenSSL::Digest("MD5") -> OpenSSL::Digest::MD5
        final Ruby runtime = self.getRuntime();
        final RubyClass Digest = runtime.getModule("OpenSSL").getClass("Digest");
        return Digest.getConstantAt( name.asString().toString() );
    }

    // API "stubs" in JRuby-OpenSSL :

    @JRubyMethod(meta = true)
    public static IRubyObject deprecated_warning_flag(final IRubyObject self) {
        return self.getRuntime().getNil(); // no-op in JRuby-OpenSSL
    }

    @JRubyMethod(meta = true, rest = true) // check_func(func, header)
    public static IRubyObject check_func(final IRubyObject self, final IRubyObject[] args) {
        return self.getRuntime().getNil(); // no-op in JRuby-OpenSSL
    }

    // Added in 2.0; not masked because it does nothing anyway (there's no reader in MRI)
    @JRubyMethod(name = "fips_mode=", meta = true)
    public static IRubyObject set_fips_mode(ThreadContext context, IRubyObject self, IRubyObject value) {
        if ( value.isTrue() ) {
            warn(context, "WARNING: FIPS mode not supported on JRuby-OpenSSL");
        }
        return value;
    }

    // internal (package-level) helpers :

    private static boolean debug;

    // on by default, warnings can be disabled using -Djruby.openssl.warn=false
    private static boolean warn = true;

    static boolean isDebug() { return debug; }

    static void debugStackTrace(final Throwable e) {
        if ( isDebug() ) e.printStackTrace(System.out);
    }

    static void debug(final String msg) {
        if ( isDebug() ) System.out.println(msg);
    }

    static void debug(final String msg, final Throwable e) {
        if ( isDebug() ) System.out.println(msg + ' ' + e);
    }

    static boolean isDebug(final Ruby runtime) {
        final RubyModule OpenSSL = runtime.getModule("OpenSSL");
        if ( OpenSSL == null ) return debug; // debug early on
        return getDebug( OpenSSL ) == runtime.getTrue();
    }

    static void debugStackTrace(final Ruby runtime, final Throwable e) {
        if ( isDebug(runtime) ) e.printStackTrace(runtime.getOut());
    }

    static void debug(final Ruby runtime, final String msg) {
        if ( isDebug(runtime) ) runtime.getOut().println(msg);
    }

    static void debug(final Ruby runtime, final String msg, final Throwable e) {
        if ( isDebug(runtime) ) runtime.getOut().println(msg + ' ' + e);
    }

    static void warn(final ThreadContext context, final String msg) {
        warn(context, RubyString.newString(context.runtime, msg));
    }

    static void warn(final ThreadContext context, final IRubyObject msg) {
        if ( warn ) context.runtime.getModule("OpenSSL").callMethod(context, "warn", msg);
    }

    private static String javaVersion(final String def) {
        final String javaVersionProperty =
                SafePropertyAccessor.getProperty("java.version", def);
        if (javaVersionProperty == "0") { // Android
            return "1.7.0";
        } else {
            return javaVersionProperty;
        }
    }

    static boolean javaVersion7(final boolean atLeast) {
        final int gt = "1.7".compareTo( javaVersion("0.0").substring(0, 3) );
        return atLeast ? gt <= 0 : gt == 0;
    }

    static boolean javaVersion8(final boolean atLeast) {
        final int gt = "1.8".compareTo( javaVersion("0.0").substring(0, 3) );
        return atLeast ? gt <= 0 : gt == 0;
    }

    private static String javaName(final String def) {
        // Sun Java 6 or Oracle Java 7/8
        // "Java HotSpot(TM) Server VM" or "Java HotSpot(TM) 64-Bit Server VM"
        // OpenJDK :
        // "OpenJDK 64-Bit Server VM"
        return SafePropertyAccessor.getProperty("java.vm.name", def);
    }

    static boolean javaHotSpot() {
        return javaName("").contains("HotSpot(TM)");
    }

    static boolean javaOpenJDK() {
        return javaName("").contains("OpenJDK");
    }

    //

    static IRubyObject to_der_if_possible(final ThreadContext context, IRubyObject obj) {
        if ( ! obj.respondsTo("to_der"))  return obj;
        return obj.callMethod(context, "to_der");
    }

    //

    static String bcExceptionMessage(NoSuchProviderException ex) {
        return "You need to configure JVM/classpath to enable BouncyCastle Security Provider: " + ex;
    }

    static String bcExceptionMessage(NoClassDefFoundError ex) {
        return "You need to configure JVM/classpath to enable BouncyCastle Security Provider: " + ex;
    }

}
