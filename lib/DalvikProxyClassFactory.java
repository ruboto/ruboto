package org.ruboto;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.reflect.Field;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.lang.reflect.Modifier;
import java.lang.reflect.UndeclaredThrowableException;
import java.security.AccessController;
import java.security.PrivilegedAction;
import java.security.ProtectionDomain;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import java.util.jar.Attributes;
import java.util.jar.JarEntry;
import java.util.jar.JarOutputStream;
import java.util.jar.Manifest;

import com.android.dx.Version;
import com.headius.android.dex.DexClient;

import dalvik.system.DexClassLoader;

public class DalvikProxyClassFactory extends org.jruby.javasupport.proxy.JavaProxyClassFactory {
    private static final String DEX_IN_JAR_NAME = "classes.dex";
    private static final Attributes.Name CREATED_BY = new Attributes.Name("Created-By");

    public Class invokeDefineClass(ClassLoader loader, String className, byte[] data) {
        String cachePath = System.getProperty("jruby.class.cache.path");
        if (cachePath != null) {
            byte[] dalvikByteCode = new DexClient().classesToDex(
                    new String[] { className.replace('.', '/') + ".class" }, new byte[][] { data });
            String jarFileName = cachePath + "/" + className.replace('.', '/') + ".jar";
            createJar(jarFileName, dalvikByteCode);
            try {
                return new DexClassLoader(jarFileName, cachePath, null, loader)
                        .loadClass(className);
            } catch (ClassNotFoundException e1) {
                System.out.println("Exception loading class with DexClassLoader: " + e1);
                e1.printStackTrace();
            }
        }
        return null;
    }

    private static boolean createJar(String fileName, byte[] dexArray) {
        File parentFile = new File(fileName).getParentFile();
        if (!parentFile.exists()) {
            System.out.println("Creating directory: " + parentFile);
            parentFile.mkdirs();
        }
        try {
            TreeMap<String, byte[]> outputResources = new TreeMap<String, byte[]>();
            Manifest manifest = makeManifest();
            OutputStream out = (fileName.equals("-") || fileName.startsWith("-.")) ? System.out
                    : new FileOutputStream(fileName);
            JarOutputStream jarOut = new JarOutputStream(out, manifest);
            outputResources.put(DEX_IN_JAR_NAME, dexArray);
            try {
                for (Map.Entry<String, byte[]> e : outputResources.entrySet()) {
                    String name = e.getKey();
                    byte[] contents = e.getValue();
                    JarEntry entry = new JarEntry(name);
                    entry.setSize(contents.length);
                    jarOut.putNextEntry(entry);
                    jarOut.write(contents);
                    jarOut.closeEntry();
                }
            } finally {
                jarOut.finish();
                jarOut.flush();
                if (out != null) {
                    out.flush();
                    if (out != System.out) {
                        out.close();
                    }
                }
                jarOut.close();
            }
        } catch (Exception ex) {
            System.out.println("Exception writing jar: " + fileName);
            System.out.println("Exception writing jar: " + ex);
            ex.printStackTrace();
            return false;
        }
        return true;
    }
    
    private static Manifest makeManifest() throws IOException {
        Manifest manifest = new Manifest();
        Attributes attribs = manifest.getMainAttributes();
        attribs.put(Attributes.Name.MANIFEST_VERSION, "1.0");
        attribs.put(CREATED_BY, "dx " + Version.VERSION);
        attribs.putValue("Dex-Location", DEX_IN_JAR_NAME);
        return manifest;
    }

}
