package jp.co.makip.saas_unisize_sdk_android_kotlin_sample

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.LruCache
import android.widget.ImageView
import java.net.HttpURLConnection
import java.net.URL

/**
 * サンプル用の簡易画像ローダーです（ライブラリ非依存）。
 * URL の画像をバックグラウンドで取得し、メインスレッドで ImageView に表示します。
 * 実アプリでは Glide / Coil 等の画像ライブラリの利用を想定しています。
 */
object SampleImageLoader {
    private const val TAG = "SampleImageLoader"
    private const val CONNECT_TIMEOUT_MS = 10_000
    private const val READ_TIMEOUT_MS = 10_000

    // 2 カラム表示のセル幅に対して過大な画像を持たないための目安です
    private const val TARGET_WIDTH_PX = 720

    private val mainHandler = Handler(Looper.getMainLooper())

    // 再取得を避けるためのメモリキャッシュ（上限 32MB）です
    private val cache =
        object : LruCache<String, Bitmap>(32 * 1024) {
            override fun sizeOf(
                key: String,
                value: Bitmap,
            ): Int = value.byteCount / 1024
        }

    /**
     * [url] の画像を [imageView] に表示します。取得に失敗した場合は何も表示しません。
     */
    fun load(
        url: String,
        imageView: ImageView,
    ) {
        if (url.isEmpty()) {
            return
        }
        cache.get(url)?.let {
            imageView.setImageBitmap(it)
            return
        }
        // 読込完了前に同じ ImageView が別 URL へ使い回された場合の取り違えを防ぎます
        imageView.tag = url
        Thread {
            val bitmap = fetch(url) ?: return@Thread
            cache.put(url, bitmap)
            mainHandler.post {
                if (imageView.tag == url) {
                    imageView.setImageBitmap(bitmap)
                }
            }
        }.start()
    }

    private fun fetch(url: String): Bitmap? {
        var connection: HttpURLConnection? = null
        return try {
            connection =
                (URL(url).openConnection() as HttpURLConnection).apply {
                    connectTimeout = CONNECT_TIMEOUT_MS
                    readTimeout = READ_TIMEOUT_MS
                }
            val bytes = connection.inputStream.use { it.readBytes() }
            decodeSampled(bytes)
        } catch (e: Exception) {
            Log.w(TAG, "画像の取得に失敗しました: $url (${e.message})")
            null
        } finally {
            connection?.disconnect()
        }
    }

    /**
     * 表示幅に対して過大な画像を inSampleSize で間引いてデコードします（OOM 対策）。
     */
    private fun decodeSampled(bytes: ByteArray): Bitmap? {
        val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
        BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
        var sampleSize = 1
        while (bounds.outWidth / (sampleSize * 2) >= TARGET_WIDTH_PX) {
            sampleSize *= 2
        }
        val options = BitmapFactory.Options().apply { inSampleSize = sampleSize }
        return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, options)
    }
}
