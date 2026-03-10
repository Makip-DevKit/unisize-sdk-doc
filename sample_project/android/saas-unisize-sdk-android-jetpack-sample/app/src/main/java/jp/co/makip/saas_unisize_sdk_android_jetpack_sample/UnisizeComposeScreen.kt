package jp.co.makip.saas_unisize_sdk_android_jetpack_sample

import android.util.Log
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import jp.co.makip.unisizesdk.UnisizeBanner
import jp.co.makip.unisizesdk.UnisizeBanner.BannerType
import jp.co.makip.unisizesdk.UnisizeBannerListener
import jp.co.makip.unisizesdk.UnisizeError
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.ui.zIndex
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

@Composable
fun UnisizeComposeScreen(
    onNavigateToCvTagTest: () -> Unit,
    onNavigateToPurchaseWebView: (beid: String, recommendedItems: String) -> Unit,
) {
    val context = LocalContext.current
    val density = LocalDensity.current
    val scope = rememberCoroutineScope()

    // パラメータ（表示用・編集用）
    var itmDisplay by remember { mutableStateOf("") }
    var cidDisplay by remember { mutableStateOf("") }
    var cuidDisplay by remember { mutableStateOf("") }
    var langDisplay by remember { mutableStateOf("ja") }

    // 適用済みパラメータ（設定ボタンで更新）
    var itm by remember { mutableStateOf("") }
    var cid by remember { mutableStateOf("") }
    var cuid by remember { mutableStateOf("") }
    var lang by remember { mutableStateOf("ja") }

    // 設定ボタンでインクリメントし、バナーの再セットアップをトリガー
    var setupTrigger by remember { mutableStateOf(0) }

    val customStyle = ""
    val sdkBnrMode = listOf(BannerType.TEXT, BannerType.EX)

    // バナー参照（Reload用）
    var textBannerRef by remember { mutableStateOf<UnisizeBanner?>(null) }
    var exBannerRef by remember { mutableStateOf<UnisizeBanner?>(null) }
    var ciBannerRef by remember { mutableStateOf<UnisizeBanner?>(null) }

    // EXバナー表示フラグ（TEXTのdidFinish後にtrue）
    var exBannerReady by remember { mutableStateOf(false) }

    // didBeidChangedで取得した値（beid、recommendedItems）は常時保持（決済画面 WebView に渡す）
    // ユーザーの操作（商品ページ閲覧、ログイン、ログアウトなど）で発火するため、常に最新の値で上書きするように実装
    // ※ 本番アプリではSharedPreferences等を使用して保持する
    var storedBeid by remember { mutableStateOf("") }
    var storedRecommendedItems by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        OutlinedTextField(
            value = itmDisplay,
            onValueChange = { itmDisplay = it },
            label = { Text("itm") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = cidDisplay,
            onValueChange = { cidDisplay = it },
            label = { Text("cid") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = cuidDisplay,
            onValueChange = { cuidDisplay = it },
            label = { Text("cuid") },
            modifier = Modifier.fillMaxWidth(),
        )
        OutlinedTextField(
            value = langDisplay,
            onValueChange = { langDisplay = it },
            label = { Text("lang") },
            modifier = Modifier.fillMaxWidth(),
        )

        Button(
            onClick = {
                if (itmDisplay.isEmpty() || cidDisplay.isEmpty()) {
                    android.widget.Toast
                        .makeText(context, "itm、またはcidが未設定です", android.widget.Toast.LENGTH_SHORT)
                        .show()
                    return@Button
                }
                itm = itmDisplay
                cid = cidDisplay
                cuid = cuidDisplay
                lang = langDisplay
                exBannerReady = false
                setupTrigger++
            },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("設定")
        }

        Spacer(modifier = Modifier.height(8.dp))

        // TEXT バナー
        var textBannerHeight by remember { mutableStateOf(60.dp) }
        var textLastSetupTrigger by remember { mutableStateOf(-1) }
        DisposableEffect(Unit) {
            onDispose {
                Log.d("UnisizeCompose", "textBannerRef onDispose()")
                textBannerRef?.onDestroy()
                textBannerRef?.destroy()
                textBannerRef = null
            }
        }
        AndroidView(
            factory = { ctx ->
                UnisizeBanner(ctx).apply {
                    textBannerRef = this
                }
            },
            // AndroidView（WebView）はデフォルトで最前面に描画されやすいため、zIndexをマイナスに設定してCompose側のUI（Button等）の背後に配置されるよう制御する
            modifier = Modifier
                .zIndex(-1f)
                .fillMaxWidth()
                .height(textBannerHeight),
            update = { view ->
                textBannerRef = view
                if (textLastSetupTrigger != setupTrigger) {
                    textLastSetupTrigger = setupTrigger
                    view.listener = object : UnisizeBannerListener {
                        override fun didFinish() {
                            Log.d("UnisizeCompose", "textWebView didFinish()")
                            scope.launch(Dispatchers.Main.immediate) {
                                exBannerReady = true
                            }
                        }

                        override fun didFail(unisizeError: UnisizeError) {
                            Log.d("UnisizeCompose", "textWebView didFail(${unisizeError.errMessage()})")
                            scope.launch(Dispatchers.Main.immediate) {
                                // WebViewはハードウェアアクセラレーション（GPU描画）を使用しており、1dp以上のサイズを維持することで、OSによる描画リソース（GPUレイヤー）の破棄を防ぎ、再表示を確実にする
                                textBannerHeight = 1.dp
                            }
                        }

                        override fun didResized(width: Int, height: Int) {
                            Log.d("UnisizeCompose", "textWebView didResized(width: $width, height: $height)")
                            scope.launch(Dispatchers.Main.immediate) {
                                textBannerHeight = with(density) { height.toDp() }
                            }
                        }

                        override fun bannerClicked() {
                            Log.d("UnisizeCompose", "textWebView bannerClicked()")
                        }

                        override fun didUnsupported(message: String) {
                            Log.d("UnisizeCompose", "textWebView didUnsupported($message)")
                            scope.launch(Dispatchers.Main.immediate) {
                                // WebViewはハードウェアアクセラレーション（GPU描画）を使用しており、1dp以上のサイズを維持することで、OSによる描画リソース（GPUレイヤー）の破棄を防ぎ、再表示を確実にする
                                textBannerHeight = 1.dp
                            }
                        }

                        override fun didBeidChanged(beid: String, recommendedItems: String, type: String) {
                            Log.d("UnisizeCompose", "textWebView didBeidChanged(beid: $beid)")
                            Log.d("UnisizeCompose", "textWebView didBeidChanged(recommendedItems: $recommendedItems)")
                            scope.launch(Dispatchers.Main.immediate) {
                                storedBeid = beid
                                storedRecommendedItems = recommendedItems
                            }
                        }
                    }
                    view.setupParam(
                        bannerType = BannerType.TEXT,
                        bannerMode = sdkBnrMode,
                        itm = itm,
                        cid = cid,
                        cuid = cuid,
                        lang = lang,
                        enableWebViewLog = true,
                        enablePrintLog = true,
                        sendErrorLog = true,
                        customStyle = customStyle,
                    )
                    view.addInterfaceToJavaScript(context)
                    view.show()
                }
            },
        )

        // EX バナー（didFinish後に表示）
        if (exBannerReady) {
            var exBannerHeight by remember { mutableStateOf(138.dp) }
            var exLastSetupTrigger by remember { mutableStateOf(-1) }
            DisposableEffect(Unit) {
                onDispose {
                    Log.d("UnisizeCompose", "exBannerRef onDispose()")
                    exBannerRef?.onDestroy()
                    exBannerRef?.destroy()
                    exBannerRef = null
                }
            }
            AndroidView(
                factory = { ctx ->
                    UnisizeBanner(ctx).apply {
                        exBannerRef = this
                    }
                },
                // AndroidView（WebView）はデフォルトで最前面に描画されやすいため、zIndexをマイナスに設定してCompose側のUI（Button等）の背後に配置されるよう制御する
                modifier = Modifier
                    .zIndex(-1f)
                    .fillMaxWidth()
                    .height(exBannerHeight),
                update = { view ->
                    exBannerRef = view
                    if (exLastSetupTrigger != setupTrigger) {
                        exLastSetupTrigger = setupTrigger
                        view.listener = object : UnisizeBannerListener {
                            override fun didFinish() {
                                Log.d("UnisizeCompose", "exWebView didFinish()")
                            }

                            override fun didFail(unisizeError: UnisizeError) {
                                Log.d("UnisizeCompose", "exWebView didFail(${unisizeError.errMessage()})")
                                scope.launch(Dispatchers.Main.immediate) {
                                    // WebViewはハードウェアアクセラレーション（GPU描画）を使用しており、1dp以上のサイズを維持することで、OSによる描画リソース（GPUレイヤー）の破棄を防ぎ、再表示を確実にする
                                    exBannerHeight = 1.dp
                                }
                            }

                            override fun didResized(width: Int, height: Int) {
                                Log.d("UnisizeCompose", "exWebView didResized(width: $width, height: $height)")
                                scope.launch(Dispatchers.Main.immediate) {
                                    exBannerHeight = with(density) { height.toDp() }
                                }
                            }

                            override fun bannerClicked() {
                                Log.d("UnisizeCompose", "exWebView bannerClicked()")
                            }

                            override fun didUnsupported(message: String) {
                                Log.d("UnisizeCompose", "exWebView didUnsupported($message)")
                                scope.launch(Dispatchers.Main.immediate) {
                                    // WebViewはハードウェアアクセラレーション（GPU描画）を使用しており、1dp以上のサイズを維持することで、OSによる描画リソース（GPUレイヤー）の破棄を防ぎ、再表示を確実にする
                                    exBannerHeight = 1.dp
                                }
                            }

                            override fun didBeidChanged(beid: String, recommendedItems: String, type: String) {
                                Log.d("UnisizeCompose", "exWebView didBeidChanged(beid: $beid)")
                                Log.d("UnisizeCompose", "exWebView didBeidChanged(recommendedItems: $recommendedItems)")
                                scope.launch(Dispatchers.Main.immediate) {
                                    storedBeid = beid
                                    storedRecommendedItems = recommendedItems
                                }
                            }
                        }
                        view.setupParam(
                            bannerType = BannerType.EX,
                            bannerMode = sdkBnrMode,
                            itm = itm,
                            cid = cid,
                            cuid = cuid,
                            lang = lang,
                            enableWebViewLog = true,
                            enablePrintLog = true,
                            sendErrorLog = true,
                            customStyle = customStyle,
                        )
                        view.addInterfaceToJavaScript(context)
                        view.show()
                    }
                },
            )
        }

        // CI バナー
        var ciBannerHeight by remember { mutableStateOf(400.dp) }
        var ciLastSetupTrigger by remember { mutableStateOf(-1) }
        DisposableEffect(Unit) {
            onDispose {
                Log.d("UnisizeCompose", "ciBannerRef onDispose()")
                ciBannerRef?.onDestroy()
                ciBannerRef?.destroy()
                ciBannerRef = null
            }
        }
        AndroidView(
            factory = { ctx ->
                UnisizeBanner(ctx).apply {
                    ciBannerRef = this
                }
            },
            // AndroidView（WebView）はデフォルトで最前面に描画されやすいため、zIndexをマイナスに設定してCompose側のUI（Button等）の背後に配置されるよう制御する
            modifier = Modifier
                .zIndex(-1f)
                .fillMaxWidth()
                .height(ciBannerHeight),
            update = { view ->
                ciBannerRef = view
                if (ciLastSetupTrigger != setupTrigger) {
                    ciLastSetupTrigger = setupTrigger
                    view.listener = object : UnisizeBannerListener {
                        override fun didFinish() {
                            Log.d("UnisizeCompose", "ciWebView didFinish")
                        }

                        override fun didFail(unisizeError: UnisizeError) {
                            Log.d("UnisizeCompose", "ciWebView didFail: ${unisizeError.errMessage()}")
                            scope.launch(Dispatchers.Main.immediate) {
                                // WebViewはハードウェアアクセラレーション（GPU描画）を使用しており、1dp以上のサイズを維持することで、OSによる描画リソース（GPUレイヤー）の破棄を防ぎ、再表示を確実にする
                                 ciBannerHeight = 1.dp
                            }
                        }

                        override fun didResized(width: Int, height: Int) {
                            Log.d("UnisizeCompose", "ciWebView didResized: width: $width, height: $height")
                            scope.launch(Dispatchers.Main.immediate) {
                                ciBannerHeight = with(density) { height.toDp() }
                            }
                        }

                        override fun bannerClicked() {
                            Log.d("UnisizeCompose", "ciWebView bannerClicked")
                        }

                        override fun didUnsupported(message: String) {
                            Log.d("UnisizeCompose", "ciWebView didUnsupported: $message")
                            scope.launch(Dispatchers.Main.immediate) {
                                // WebViewはハードウェアアクセラレーション（GPU描画）を使用しており、1dp以上のサイズを維持することで、OSによる描画リソース（GPUレイヤー）の破棄を防ぎ、再表示を確実にする
                                ciBannerHeight = 1.dp
                            }
                        }

                        override fun didBeidChanged(beid: String, recommendedItems: String, type: String) {
                            Log.d("UnisizeCompose", "ciWebView didBeidChanged(beid: $beid)")
                        }
                    }
                    view.setupParam(
                        bannerType = BannerType.CI,
                        bannerMode = sdkBnrMode,
                        itm = itm,
                        cid = cid,
                        cuid = cuid,
                        lang = lang,
                        enableWebViewLog = true,
                        enablePrintLog = true,
                        sendErrorLog = true,
                        customStyle = customStyle,
                    )
                    view.addInterfaceToJavaScript(context)
                    view.show()
                }
            },
        )

        Button(
            onClick = {
                textBannerRef?.reload()
                exBannerRef?.reload()
                ciBannerRef?.reload()
            },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("Reload")
        }

        // unisizeCvTag Class を使用せずに実装する場合
        // アプリケーション内に購入機能を持たない場合(決済はWebView)
        Button(
            onClick = { onNavigateToPurchaseWebView(storedBeid, storedRecommendedItems) },
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("決済画面を開く（WebView）")
        }

        // unisizeCvTag Class を使用して実装する場合
        // アプリケーション内に購入機能(画面)を持つ場合
        Button(
            onClick = onNavigateToCvTagTest,
            modifier = Modifier.fillMaxWidth(),
        ) {
            Text("CVTagテスト")
        }
    }
}
