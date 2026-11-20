package com.xmsj.shouyin.shouyin_android;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.util.Arrays;

/** Dependency-free native boundary regression; run with javac/java. */
public final class ProductImageReaderTest {
    private static final byte[] PNG = {(byte)137, 80, 78, 71, 13, 10, 26, 10};
    private static void check(boolean value) { if (!value) throw new AssertionError(); }
    private static void rejected(byte[] bytes) throws Exception {
        try {
            ProductImageReader.read(new ByteArrayInputStream(bytes));
            throw new AssertionError("invalid image accepted");
        } catch (IOException expected) { }
    }
    public static void main(String[] args) throws Exception {
        check(Arrays.equals(PNG, ProductImageReader.read(new ByteArrayInputStream(PNG))));
        byte[] jpeg = {(byte)255, (byte)216, (byte)255, (byte)224};
        check(Arrays.equals(jpeg, ProductImageReader.read(new ByteArrayInputStream(jpeg))));
        rejected(new byte[0]);
        rejected("<svg></svg>".getBytes(java.nio.charset.StandardCharsets.UTF_8));
        byte[] largest = Arrays.copyOf(PNG, 500 * 1024 - 1);
        check(ProductImageReader.read(new ByteArrayInputStream(largest)).length == largest.length);
        rejected(Arrays.copyOf(PNG, 500 * 1024));
        rejected(Arrays.copyOf(PNG, 500 * 1024 + 8192));
        System.out.println("ProductImageReader: 7 boundary checks passed");
    }
}
