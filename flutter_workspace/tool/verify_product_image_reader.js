'use strict';

// Native byte-boundary regression, independent of Android UI and external uploads.
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const root = path.resolve(__dirname, '../apps/android_app/android/app/src');
const output = fs.mkdtempSync(path.join(os.tmpdir(), 'shouyin-image-reader-'));
const binary = name => process.env.JAVA_HOME
  ? path.join(process.env.JAVA_HOME, 'bin', name) : name;
function run(name, args) {
  const result = spawnSync(binary(name), args, { stdio: 'inherit' });
  if (result.error || result.status !== 0) throw new Error(`${name} failed`);
}
try {
  run('javac', ['-d', output,
    path.join(root, 'main/java/com/xmsj/shouyin/shouyin_android/ProductImageReader.java'),
    path.join(root, 'test/java/com/xmsj/shouyin/shouyin_android/ProductImageReaderTest.java')]);
  run('java', ['-cp', output, 'com.xmsj.shouyin.shouyin_android.ProductImageReaderTest']);
} finally {
  // Only the dedicated directory created above contains generated .class files.
  fs.rmSync(output, { recursive: true, force: true });
}
