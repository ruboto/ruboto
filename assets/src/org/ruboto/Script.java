package org.ruboto;

import java.io.BufferedOutputStream;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.lang.reflect.InvocationTargetException;
import java.lang.reflect.Method;
import java.net.URL;

import android.content.Context;
import android.content.res.AssetManager;
import android.os.Environment;

public class Script {
    private static String[] scriptsDir = new String[]{"scripts"};

    private final String name;

    public static void addDir(String dir) {
        String[] oldScriptsDir = scriptsDir;
    	scriptsDir = new String[scriptsDir.length + 1];
    	scriptsDir[0] = dir;
    	for(int i = 0 ; i < oldScriptsDir.length ; i++) {
    	    scriptsDir[i + 1] = oldScriptsDir[i];
    	}
    }

    public static String toCamelCase(String s) {
        String[] parts = s.replace(".rb", "").split("_");
        for (int i = 0 ; i < parts.length ; i++) {
            if (parts[i].length() == 0) continue;
            parts[i] = parts[i].substring(0,1).toUpperCase() + parts[i].substring(1);
        }
        return java.util.Arrays.toString(parts).replace(", ", "").replaceAll("[\\[\\]]", "");
    }

    public static String toSnakeCase(String s) {
        return s.replaceAll(
            String.format("%s|%s|%s",
                "(?<=[A-Z])(?=[A-Z][a-z0-9])",
                "(?<=[^A-Z])(?=[A-Z])",
                "(?<=[A-Za-z0-9])(?=[^A-Za-z0-9])"
            ),
            "_"
        ).replace("__", "_").toLowerCase();
    }

    // Private static methods

    // private static void copyAssets(Context context, String directory) {
    // 	File dest = new File(new File(scriptsDirFile).getParentFile(), directory);
	// 	if (dest.exists() || dest.mkdir()) {
    //         copyScripts(directory, dest, context.getAssets());
	// 	} else {
    //         throw new RuntimeException("Unable to create scripts directory: " + dest);
	// 	}
    // }

    // private static void copyScripts(String from, File to, AssetManager assets) {
    //     try {
    //         byte[] buffer = new byte[8192];
    //         for (String f : assets.list(from)) {
    //             File dest = new File(to, f);
    //
    //             if (dest.exists()) {
    //                 continue;
    //             }
    //
    //             Log.d("copying file from " + from + "/" + f + " to " + dest);
    //
    //             if (assets.list(from + "/" + f).length == 0) {
    //                 InputStream is = assets.open(from + "/" + f);
    //                 OutputStream fos = new BufferedOutputStream(new FileOutputStream(dest), 8192);
    //
    //                 int n;
    //                 while ((n = is.read(buffer, 0, buffer.length)) != -1) {
    //                     fos.write(buffer, 0, n);
    //                 }
    //                 is.close();
    //                 fos.close();
    //             } else {
    //                 dest.mkdir();
    //                 copyScripts(from + "/" + f, dest, assets);
    //             }
    //         }
    //     } catch (IOException iox) {
    //         Log.e("error copying scripts", iox);
    //     }
    // }

    /*************************************************************************************************
     *
     * Constructors
     */
    public Script(String name) {
        this.name = name;
    }

    /*************************************************************************************************
     *
     * Instance methods
     */
    public String execute() throws IOException {
        return JRubyAdapter.execute(getContents());
    }

    boolean exists() {
        return getAbsolutePath() != null;
    }

    String getAbsolutePath() {
        for (String dir : scriptsDir) {
            String path = dir + "/" + name;
            Log.d("Checking path: " + path);
            if (new File(path).exists()) {
                return "file:" + path;
            }
        }
        URL url = getClass().getClassLoader().getResource(name);
        Log.d("Classpath resource: " + url);
        if (url != null) {
            return url.toString();
        }
        return null;
    }

    public File getFile() {
        for (String dir : scriptsDir) {
            File f = new File(dir, name);
            if (f.exists()) {
                return f;
            }
        }
        return new File(scriptsDir[0], name);
    }
		
    public String getContents() throws IOException {
        InputStream is = null;
        BufferedReader buffer = null;
        try {
            buffer = new BufferedReader(new java.io.InputStreamReader(new URL(getAbsolutePath()).openStream()), 8192);
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

    public String getName() {
        return name;
    }

}
