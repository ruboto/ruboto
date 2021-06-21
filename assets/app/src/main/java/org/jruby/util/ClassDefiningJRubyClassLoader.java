/*
 **** BEGIN LICENSE BLOCK *****
 * Version: EPL 2.0/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Eclipse Public
 * License Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License. You may obtain a copy of
 * the License at http://www.eclipse.org/legal/epl-v20.html
 *
 * Software distributed under the License is distributed on an "AS
 * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
 * implied. See the License for the specific language governing
 * rights and limitations under the License.
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either of the GNU General Public License Version 2 or later (the "GPL"),
 * or the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the EPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the EPL, the GPL or the LGPL.
 ***** END LICENSE BLOCK *****/

package org.jruby.util;

import com.android.dex.Dex;
import com.android.dx.cf.direct.DirectClassFile;
import com.android.dx.cf.direct.StdAttributeFactory;
import com.android.dx.dex.DexOptions;
import com.android.dx.dex.cf.CfOptions;
import com.android.dx.dex.cf.CfTranslator;
import com.android.dx.dex.file.DexFile;

import java.io.IOException;
import java.net.URL;
import java.net.URLClassLoader;
import java.nio.ByteBuffer;
import java.security.ProtectionDomain;

import dalvik.system.InMemoryDexClassLoader;

public class ClassDefiningJRubyClassLoader extends URLClassLoader implements ClassDefiningClassLoader {

    final static ProtectionDomain DEFAULT_DOMAIN;

    static {
        ProtectionDomain defaultDomain = null;
        try {
            defaultDomain = JRubyClassLoader.class.getProtectionDomain();
        } catch (SecurityException se) {
            // just use null since we can't acquire protection domain
        }
        DEFAULT_DOMAIN = defaultDomain;
    }

    public ClassDefiningJRubyClassLoader(ClassLoader parent) {
        super(new URL[0], parent);
    }

    public Class<?> defineClass(String name, byte[] bytes) {
        return defineClass(name, bytes, DEFAULT_DOMAIN);
    }

    public Class<?> defineClass(String name, byte[] bytes, ProtectionDomain domain) {
        System.out.println("defineClass: name: " + name);

        DexOptions dexOptions = new DexOptions();
        DexFile dexFile = new DexFile(dexOptions);
        DirectClassFile classFile = new DirectClassFile(bytes, name.replace('.', '/') + ".class", true);
        classFile.setAttributeFactory(StdAttributeFactory.THE_ONE);
        classFile.getMagic();
        dexFile.add(CfTranslator.translate(classFile, null, new CfOptions(), dexOptions, dexFile));

        try {
            Dex dex = new Dex(dexFile.toDex(null, false));
            return new InMemoryDexClassLoader(ByteBuffer.wrap(dex.getBytes()), this).loadClass(name);
        } catch (IOException | ClassNotFoundException e1) {
            System.out.println("Exception loading class with DexClassLoader: " + e1);
            e1.printStackTrace();
        }
        return null;
    }
}
