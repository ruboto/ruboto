package org.ruboto;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import android.content.Context;
import android.content.res.AssetManager;

public class Script {
    private static String scriptsDir = "scripts";
    private static File scriptsDirFile = null;

    private String name = null;

    /*************************************************************************************************
    *
    * Static Methods: Scripts Directory
    */
    public static void setDir(String dir) {
    	scriptsDir = dir;
    	scriptsDirFile = new File(dir);
        if (JRubyAdapter.isInitialized()) {
            Log.d("Changing JRuby current directory to " + scriptsDir);
            JRubyAdapter.callScriptingContainerMethod(Void.class, "setCurrentDirectory", scriptsDir);
        }
    }
    
    public static String getDir() {
    	return scriptsDir;
    }

    public static File getDirFile() {
    	return scriptsDirFile;
    }

    private static void copyScripts(String from, File to, AssetManager assets) {
        try {
            byte[] buffer = new byte[8192];
            for (String f : assets.list(from)) {
                File dest = new File(to, f);

                if (dest.exists()) {
                    continue;
                }

                Log.d("copying file from " + from + "/" + f + " to " + dest);

                if (assets.list(from + "/" + f).length == 0) {
                    InputStream is = assets.open(from + "/" + f);
                    OutputStream fos = new BufferedOutputStream(new FileOutputStream(dest), 8192);

                    int n;
                    while ((n = is.read(buffer, 0, buffer.length)) != -1) {
                        fos.write(buffer, 0, n);
                    }
                    is.close();
                    fos.close();
                } else {
                    dest.mkdir();
                    copyScripts(from + "/" + f, dest, assets);
                }
            }
        } catch (IOException iox) {
            Log.e("error copying scripts", iox);
        }
    }

    public static void copyAssets(Context context, String directory) {
    	File dest = new File(scriptsDirFile.getParentFile(), directory);
		if (dest.exists() || dest.mkdir()) {
            copyScripts(directory, dest, context.getAssets());
		} else {
            throw new RuntimeException("Unable to create scripts directory: " + dest);
		}
    }
    
     /*************************************************************************************************
    *
    * Constructors
    */

    public Script(String name) {
        this.name = name;
    }

    /*************************************************************************************************
     *
     * Attribute Access
     */

    public String getName() {
        return name;
    }

    public File getFile() {
        return new File(getDir(), name);
    }

    public Script setName(String name) {
        this.name = name;
        return this;
    }

    public String getContents() throws IOException {
        InputStream is = null;
        BufferedReader buffer = null;
        try {
            if (new File(scriptsDir + "/" + name).exists()) {
                is = new java.io.FileInputStream(scriptsDir + "/" + name);
            } else {
                is = getClass().getClassLoader().getResourceAsStream(name);
            }
                buffer = new BufferedReader(new java.io.InputStreamReader(is), 8192);
            StringBuilder source = new StringBuilder();
            while (true) {
                String line = buffer.readLine();
                if (line == null) {
                    break;
                }
                source.append(line).append("\n");
            }
            return source.toString();
		} finally {
			if (is != null) {
				is.close();
			}
			if (is != null) {
				buffer.close();
			}
		}
	}

    /*************************************************************************************************
     *
     * Script Actions
     */

    public static String toSnakeCase(String s) {
        return s.replaceAll(
            String.format("%s|%s|%s",
                "(?<=[A-Z])(?=[A-Z][a-z])",
                "(?<=[^A-Z])(?=[A-Z])",
                "(?<=[A-Za-z])(?=[^A-Za-z])"
            ),
            "_"
        ).toLowerCase();
    }

    public static String toCamelCase(String s) {
        String[] parts = s.replace(".rb", "").split("_");
        for (int i = 0 ; i < parts.length ; i++) {
            parts[i] = parts[i].substring(0,1).toUpperCase() + parts[i].substring(1);
        }
        return java.util.Arrays.toString(parts).replace(", ", "").replaceAll("[\\[\\]]", "");
    }

    public String execute() throws IOException {
        return JRubyAdapter.execute(getContents());
    }

}
