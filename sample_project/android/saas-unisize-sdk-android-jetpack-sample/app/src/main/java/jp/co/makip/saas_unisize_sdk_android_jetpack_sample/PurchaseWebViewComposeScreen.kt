package jp.co.makip.saas_unisize_sdk_android_jetpack_sample

import android.util.Log
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView

private const val BASE_URL = "https://example.com/"

private val PAYMENT_HTML = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>決済画面</title>
    <style>
        body { font-family: sans-serif; padding: 20px; }
        h1 { font-size: 1.2em; }
        button { padding: 12px 24px; font-size: 16px; margin-top: 16px; }
    </style>
</head>
<body>
    <h1>決済画面</h1>
    <p>サンプル用の架空の決済画面です。</p>
    <button onclick="location.href='https://example.com/complete.html'">購入完了</button>
</body>
</html>
""".trimIndent()

private val COMPLETE_HTML = """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>購入完了</title>
    <style>
        body { font-family: sans-serif; padding: 20px; }
        h1 { font-size: 1.2em; }
        .debug { background: #f0f0f0; padding: 12px; margin-top: 16px; font-size: 12px; word-break: break-all; }
    </style>
</head>
<body>
    <h1>購入完了</h1>
    <p>ご購入ありがとうございます。</p>
    <p>以下は CV タグ連携サンプル用のデバッグ表示です。Web 版 unisize の CV タグは localStorage、Cookie から _unisize_beid と _unisize_recommended_items を読み取ります。</p>
    <div class="debug">
        <strong>_unisize_beid:</strong><br>
        <span id="beid"></span>
    </div>
    <div class="debug">
        <strong>_unisize_recommended_items:</strong><br>
        <span id="recommendedItems"></span>
    </div>
    <script>
        document.getElementById('beid').textContent = localStorage.getItem('_unisize_beid') || '(未設定)';
        document.getElementById('recommendedItems').textContent = localStorage.getItem('_unisize_recommended_items') || '(未設定)';
    </script>
</body>
</html>
""".trimIndent()

@Composable
fun PurchaseWebViewComposeScreen(
    beid: String,
    recommendedItems: String,
    onClose: () -> Unit,
) {
    val fixedRecommendedItems = if (recommendedItems.isBlank()) "[]" else recommendedItems
    val webViewRef = remember { mutableStateOf<WebView?>(null) }

    DisposableEffect(Unit) {
        onDispose {
            Log.d("PurchaseWebViewComposeScreen", "onDispose()")
            webViewRef.value?.destroy()
            webViewRef.value = null
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
    ) {
        AndroidView(
            factory = { ctx ->
                WebView(ctx).also { webViewRef.value = it }.apply {
                    settings.apply {
                        javaScriptEnabled = true
                        domStorageEnabled = true
                    }
                    val defaultUA = WebSettings.getDefaultUserAgent(ctx)
                    // unisize のコンバージョンの集計時にアプリ判定を行うために必要
                    // 「unisizeSDK」の有無で unisizeSDK でのアクセスかを判定しています
                    settings.userAgentString = "$defaultUA unisizeSDK"
                    webViewClient = object : WebViewClient() {
                        override fun onPageFinished(view: WebView?, url: String?) {
                            super.onPageFinished(view, url)
                            if (view != null && url != null && url.startsWith(BASE_URL)) {
                                val jsCode = """
                                    var date = new Date();
                                    date.setTime(date.getTime() + (365 * 24 * 60 * 60 * 1000));
                                    var expires = "; expires=" + date.toUTCString();
                                    document.cookie = "_unisize_beid=$beid; path=/; expires=" + expires;
                                    if (typeof(Storage) !== "undefined") {
                                        localStorage.setItem('_unisize_beid', '$beid');
                                        localStorage.setItem('_unisize_recommended_items', '$fixedRecommendedItems');
                                    }
                                """.trimIndent()
                                view.evaluateJavascript(jsCode, null)
                            }
                        }

                        override fun shouldOverrideUrlLoading(
                            view: WebView,
                            request: WebResourceRequest,
                        ): Boolean {
                            if (request.url.toString() == "${BASE_URL}complete.html") {
                                view.loadDataWithBaseURL(
                                    BASE_URL,
                                    COMPLETE_HTML,
                                    "text/html",
                                    "UTF-8",
                                    null,
                                )
                                return true
                            }
                            return false
                        }
                    }
                    loadDataWithBaseURL(
                        BASE_URL,
                        PAYMENT_HTML,
                        "text/html",
                        "UTF-8",
                        null,
                    )
                }
            },
            modifier = Modifier
                .fillMaxSize()
                .weight(1f),
        )

        Button(
            onClick = onClose,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("閉じる")
        }
    }
}
