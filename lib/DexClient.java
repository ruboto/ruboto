package com.headius.android.dex;

import com.android.dex.DexFormat;
import com.android.dx.Version;
import com.android.dx.cf.direct.ClassPathOpener;
import com.android.dx.cf.direct.DirectClassFile;
import com.android.dx.cf.iface.ParseException;
import com.android.dx.command.DxConsole;
import com.android.dx.command.UsageException;
import com.android.dx.dex.DexOptions;
import com.android.dx.dex.cf.CfOptions;
import com.android.dx.dex.cf.CfTranslator;
import com.android.dx.dex.cf.CodeStatistics;
import com.android.dx.dex.code.PositionList;
import com.android.dx.dex.file.ClassDefItem;
import com.android.dx.dex.file.DexFile;
import com.android.dx.dex.file.EncodedMethod;
import com.android.dx.rop.annotation.Annotation;
import com.android.dx.rop.annotation.Annotations;
import com.android.dx.rop.annotation.AnnotationsList;
import com.android.dx.rop.cst.CstNat;
// import com.android.dx.rop.cst.CstUtf8;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Map;
import java.util.TreeMap;
import java.util.jar.Attributes;
import java.util.jar.JarEntry;
import java.util.jar.JarOutputStream;
import java.util.jar.Manifest;

public class DexClient {
    /** number of warnings during processing */
    private static int warnings = 0;

    /** number of errors during processing */
    private static int errors = 0;

    /** {@code non-null;} output file in-progress */
    private static DexFile outputDex;
    private static DexOptions dexOptions = new DexOptions();
    static {
        dexOptions.targetApiLevel = DexFormat.API_NO_EXTENDED_OPCODES;
    }
    private final CfOptions cfOptions;

    public DexClient() {
        outputDex = new DexFile(dexOptions);
        cfOptions = new CfOptions();

        cfOptions.positionInfo = PositionList.LINES;
        cfOptions.localInfo = true;
        cfOptions.strictNameCheck = true;
        cfOptions.optimize = false;
        cfOptions.optimizeListFile = null;
        cfOptions.dontOptimizeListFile = null;
        cfOptions.statistics = false;
    }

    public byte[] classesToDex(String[] names, byte[][] byteArrays) {
      for (int i = 0; i < names.length; i++) {
        String name = names[i];
        byte[] byteArray = byteArrays[i];
        processClass(name, byteArray);
      }

      byte[] outputArray = writeDex();

      return outputArray;
    }

    /**
     * Processes one classfile.
     *
     * @param name {@code non-null;} name of the file, clipped such that it
     * <i>should</i> correspond to the name of the class it contains
     * @param bytes {@code non-null;} contents of the file
     * @return whether processing was successful
     */
    private boolean processClass(String name, byte[] bytes) {
        try {
            ClassDefItem clazz = CfTranslator
                    .translate(new DirectClassFile(bytes, name, true), bytes, cfOptions, dexOptions, outputDex);
            return true;
        } catch (ParseException ex) {
          ex.printStackTrace();
        }

        warnings++;
        return false;
    }

    /**
     * Converts {@link #outputDex} into a {@code byte[]}, write
     * it out to the proper file (if any), and also do whatever human-oriented
     * dumping is required.
     *
     * @return {@code null-ok;} the converted {@code byte[]} or {@code null}
     * if there was a problem
     */
    private byte[] writeDex() {
        byte[] outArray = null;

        OutputStreamWriter out = new OutputStreamWriter(new ByteArrayOutputStream());
        try {
            outArray = outputDex.toDex(out, false);
        } catch (Exception ex) {
          ex.printStackTrace();
        }

        return outArray;
    }

    /**
     * Opens and returns the named file for writing, treating "-" specially.
     *
     * @param name {@code non-null;} the file name
     * @return {@code non-null;} the opened file
     */
    private OutputStream openOutput(String name) throws IOException {
        if (name.equals("-") ||
                name.startsWith("-.")) {
            return System.out;
        }

        return new FileOutputStream(name);
    }

    /**
     * Flushes and closes the given output stream, except if it happens to be
     * {@link System#out} in which case this method does the flush but not
     * the close. This method will also silently do nothing if given a
     * {@code null} argument.
     *
     * @param stream {@code null-ok;} what to close
     */
    private void closeOutput(OutputStream stream) throws IOException {
        if (stream == null) {
            return;
        }

        stream.flush();

        if (stream != System.out) {
            stream.close();
        }
    }
}