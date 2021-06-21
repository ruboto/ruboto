package org.jruby.util;

import com.android.dex.Dex;
import com.android.dx.cf.direct.DirectClassFile;
import com.android.dx.cf.direct.StdAttributeFactory;
import com.android.dx.dex.DexOptions;
import com.android.dx.dex.cf.CfOptions;
import com.android.dx.dex.cf.CfTranslator;
import com.android.dx.dex.file.DexFile;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;

import dalvik.system.InMemoryDexClassLoader;

/**
 * Represents a class loader designed to load exactly one class.
 */
public class OneShotClassLoader extends ClassLoader implements ClassDefiningClassLoader {
    private final Map<String, Class> extraClassDefs = new HashMap<>();

    public OneShotClassLoader(JRubyClassLoader parent) {
        super(parent);

    }

    public OneShotClassLoader(ClassLoader parent) {
        super(parent);
    }

    @Override
    protected Class<?> findClass(final String name) throws ClassNotFoundException {
        Class aClass = this.extraClassDefs.remove(name);
        if (aClass != null) {
            return aClass;
        }
        return super.findClass(name);
    }

    public Class<?> defineClass(String name, byte[] bytes) {
        System.out.println("defineClass: name: " + name);

        DexOptions dexOptions = new DexOptions();
        DexFile dexFile = new DexFile(dexOptions);
        DirectClassFile classFile = new DirectClassFile(bytes, name.replace('.', '/') + ".class", true);
        classFile.setAttributeFactory(StdAttributeFactory.THE_ONE);
        classFile.getMagic();
        dexFile.add(CfTranslator.translate(classFile, null, new CfOptions(), dexOptions, dexFile));

        try {
            Dex dex = new Dex(dexFile.toDex(null, false));
            byte[] dexBytes = dex.getBytes();
            Class<?> aClass = new InMemoryDexClassLoader(ByteBuffer.wrap(dexBytes), this).loadClass(name);
            extraClassDefs.put(name, aClass);
            return aClass;
        } catch (IOException e1) {
            System.out.println("Exception loading class with DexClassLoader: " + e1);
            e1.printStackTrace();
        } catch (ClassNotFoundException e) {
            e.printStackTrace();
        }
        return null;
    }
}
