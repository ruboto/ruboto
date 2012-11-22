package com.headius.android.dex;

import java.io.ByteArrayOutputStream;
import java.io.OutputStreamWriter;

import com.android.dx.cf.iface.ParseException;
import com.android.dx.dex.DexFormat;
import com.android.dx.dex.DexOptions;
import com.android.dx.dex.cf.CfOptions;
import com.android.dx.dex.cf.CfTranslator;
import com.android.dx.dex.code.PositionList;
import com.android.dx.dex.file.ClassDefItem;
import com.android.dx.dex.file.DexFile;

public class DexClient {
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
            ClassDefItem clazz;
            clazz = CfTranslator.translate(name, bytes, cfOptions, dexOptions);
            outputDex.add(clazz);
            return true;
        } catch (ParseException ex) {
          ex.printStackTrace();
        }

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
}
