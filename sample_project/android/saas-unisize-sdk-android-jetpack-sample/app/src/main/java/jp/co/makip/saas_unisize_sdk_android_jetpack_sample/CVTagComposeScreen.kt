package jp.co.makip.saas_unisize_sdk_android_jetpack_sample

import android.util.Log
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import jp.co.makip.unisizesdk.UnisizeCVTag
import jp.co.makip.unisizesdk.UnisizeCVTagListener
import jp.co.makip.unisizesdk.UnisizeError

@Composable
fun CVTagComposeScreen(
    onClose: () -> Unit,
) {
    var cvTagRef by remember { mutableStateOf<UnisizeCVTag?>(null) }
    var hasSetup by remember { mutableStateOf(false) }

    // Javascriptに渡す値（※検証用のサンプルデータ）
    val cid: String = ""
    val cuid: String = ""
    val purchaseid: String = ""
    val itemnum: List<String> = listOf("")
    val itemid: List<String> = listOf("")
    val price: List<String> = listOf("")
    val size: List<String> = listOf("")
    val iteminfo: String = ""

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        DisposableEffect(Unit) {
            onDispose {
                Log.d("UnisizeCVTag", "cvTagRef onDispose()")
                cvTagRef?.destroy()
                cvTagRef = null
            }
        }
        AndroidView(
            factory = { ctx ->
                UnisizeCVTag(ctx).apply {
                    cvTagRef = this
                }
            },
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp),
            update = { view ->
                cvTagRef = view
                if (!hasSetup) {
                    hasSetup = true
                    view.listener = object : UnisizeCVTagListener {
                        override fun didFinish() {
                            Log.d("UnisizeCVTag", "didFinish()")
                        }

                        override fun didFail(unisizeError: UnisizeError) {
                            val message = unisizeError.errMessage()
                            Log.d("UnisizeCVTag", "didFail(${message})")
                        }
                    }
                    Log.d("UnisizeCVTag", "setupParam()")
                    Log.d("UnisizeCVTag", "cid: $cid")
                    Log.d("UnisizeCVTag", "cuid: $cuid")
                    Log.d("UnisizeCVTag", "purchaseid: $purchaseid")
                    Log.d("UnisizeCVTag", "itemnum: $itemnum")
                    Log.d("UnisizeCVTag", "itemid: $itemid")
                    Log.d("UnisizeCVTag", "price: $price")
                    Log.d("UnisizeCVTag", "size: $size")
                    Log.d("UnisizeCVTag", "iteminfo: $iteminfo")
                    view.setupParam(
                        cid,
                        cuid,
                        purchaseid,
                        itemnum,
                        itemid,
                        price,
                        size,
                        iteminfo,
                        "",
                        "",
                        true,
                        true,
                    )
                    view.show()
                }
            },
        )

        // WebViewリロードボタン（通信検証用）
        Button(
            onClick = { cvTagRef?.reload() },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Reload")
        }

        Button(
            onClick = onClose,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Close")
        }
    }
}
