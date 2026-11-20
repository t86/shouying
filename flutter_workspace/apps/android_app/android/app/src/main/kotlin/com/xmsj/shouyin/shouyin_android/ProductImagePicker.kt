package com.xmsj.shouyin.shouyin_android

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/** SAF grants access only to explicitly selected documents, without storage permission. */
class ProductImagePicker(private val activity: Activity, messenger: BinaryMessenger) {
    private val channel = MethodChannel(messenger, "shouyin/product_images")
    private val executor = Executors.newSingleThreadExecutor()
    private val handles = ConcurrentHashMap<String, Uri>()
    private var pending: MethodChannel.Result? = null
    private var multiple = false
    @Volatile private var disposed = false

    init { channel.setMethodCallHandler(::onCall) }

    private fun onCall(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        if (call.arguments != null && arguments == null) {
            result.error("invalid_arguments", "图片选择参数无效", null)
            return
        }
        when (call.method) {
            "pickImages" -> {
                if (pending != null) {
                    result.error("picker_busy", "图片选择器已打开", null)
                    return
                }
                val allowMultiple = arguments?.get("multiple")
                if (allowMultiple != null && allowMultiple !is Boolean) {
                    result.error("invalid_arguments", "图片选择参数无效", null)
                    return
                }
                multiple = allowMultiple == true
                pending = result
                try {
                    activity.startActivityForResult(Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "image/*"
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/png", "image/jpeg"))
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, multiple)
                    }, REQUEST_CODE)
                } catch (_: Exception) {
                    pending = null
                    result.error("picker_unavailable", "设备没有可用的图片选择器", null)
                }
            }
            "readImage" -> {
                val id = arguments?.get("id") as? String
                val uri = if (id == null) null else handles[id]
                if (uri == null) {
                    result.error("image_released", "图片选择已失效，请重新选择", null)
                    return
                }
                executor.execute {
                    try {
                        val bytes = activity.contentResolver.openInputStream(uri)?.use {
                            ProductImageReader.read(it)
                        } ?: throw IllegalStateException()
                        activity.runOnUiThread {
                            if (!disposed) {
                                if (handles[id] == uri) result.success(bytes)
                                else result.error("image_released", "图片选择已失效，请重新选择", null)
                            }
                        }
                    } catch (_: Exception) {
                        activity.runOnUiThread {
                            if (!disposed) result.error("image_read_failed", "图片无法读取，请选择小于500KB的PNG或JPEG图片", null)
                        }
                    }
                }
            }
            "releaseImages" -> {
                val ids = arguments?.get("ids")
                if (ids == null) {
                    handles.clear()
                } else if (ids is List<*> && ids.all { it is String }) {
                    ids.forEach { handles.remove(it as String) }
                } else {
                    result.error("invalid_arguments", "图片释放参数无效", null)
                    return
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_CODE) return false
        val result = pending ?: return true
        if (resultCode != Activity.RESULT_OK || data == null) {
            pending = null
            result.success(null)
            return true
        }
        val uris = linkedSetOf<Uri>()
        val clip = data.clipData
        if (clip != null && clip.itemCount > MAX_IMAGES) {
            pending = null
            result.error("too_many_images", "每批最多选择200张图片", null)
            return true
        }
        if (clip != null) for (index in 0 until clip.itemCount) {
            clip.getItemAt(index).uri?.let { uris.add(it) }
        }
        data.data?.let { uris.add(it) }
        if (uris.size > MAX_IMAGES || (!multiple && uris.size > 1)) {
            pending = null
            result.error("too_many_images", "图片数量超出本次选择范围", null)
            return true
        }
        executor.execute {
            val newHandles = mutableListOf<String>()
            try {
                val images = uris.map { uri ->
                    var name = "image"
                    var size: Long? = null
                    activity.contentResolver.query(uri,
                        arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                        null, null, null)?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                            val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                            if (nameIndex >= 0 && !cursor.isNull(nameIndex)) name = cursor.getString(nameIndex)
                            if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex).takeIf { it >= 0 }
                        }
                    }
                    val id = UUID.randomUUID().toString()
                    handles[id] = uri
                    newHandles.add(id)
                    mapOf("id" to id, "name" to name, "size" to size)
                }
                activity.runOnUiThread {
                    if (!disposed) {
                        pending = null
                        result.success(images)
                    } else newHandles.forEach { handles.remove(it) }
                }
            } catch (_: Exception) {
                newHandles.forEach { handles.remove(it) }
                activity.runOnUiThread {
                    if (!disposed) {
                        pending = null
                        result.error("image_selection_failed", "无法读取所选图片信息，请重试", null)
                    }
                }
            }
        }
        return true
    }

    fun dispose() {
        if (disposed) return
        disposed = true
        channel.setMethodCallHandler(null)
        pending?.success(null)
        pending = null
        handles.clear()
        executor.shutdownNow()
    }

    companion object {
        private const val REQUEST_CODE = 47159
        private const val MAX_IMAGES = 200
    }
}
