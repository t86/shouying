package com.xmsj.shouyin.shouyin_android;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

/** Reads one user-selected image; size hints from content providers are untrusted. */
public final class ProductImageReader {
    public static final int MAX_BYTES = 500 * 1024;
    private ProductImageReader() { }

    public static byte[] read(InputStream input) throws IOException {
        ByteArrayOutputStream output = new ByteArrayOutputStream(8192);
        byte[] buffer = new byte[8192];
        int count;
        while ((count = input.read(buffer)) != -1) {
            if (Thread.currentThread().isInterrupted()) throw new IOException("cancelled");
            if (count == 0) {
                int single = input.read();
                if (single < 0) break;
                if (output.size() + 1 >= MAX_BYTES) throw new IOException("too large");
                output.write(single);
            } else {
                if (output.size() + count >= MAX_BYTES) throw new IOException("too large");
                output.write(buffer, 0, count);
            }
        }
        byte[] bytes = output.toByteArray();
        boolean jpeg = bytes.length >= 3 && (bytes[0] & 255) == 255
                && (bytes[1] & 255) == 216 && (bytes[2] & 255) == 255;
        boolean png = bytes.length >= 8 && (bytes[0] & 255) == 137
                && bytes[1] == 80 && bytes[2] == 78 && bytes[3] == 71
                && bytes[4] == 13 && bytes[5] == 10 && bytes[6] == 26 && bytes[7] == 10;
        if (!jpeg && !png) throw new IOException("unsupported image");
        return bytes;
    }
}
