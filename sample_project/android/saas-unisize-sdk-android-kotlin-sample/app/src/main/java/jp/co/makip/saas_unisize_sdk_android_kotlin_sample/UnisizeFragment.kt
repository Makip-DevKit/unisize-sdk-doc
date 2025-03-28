package jp.co.makip.saas_unisize_sdk_android_kotlin_sample

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.fragment.app.Fragment
import jp.co.makip.unisizesdk.UnisizeBanner.BannerType
import java.util.stream.Collectors

class UnisizeFragment : Fragment(R.layout.fragment_unisize) {
    // UnisizeBannerのインスタンスを保持
    private lateinit var textWebView: jp.co.makip.unisizesdk.UnisizeBanner
    private var exWebView: jp.co.makip.unisizesdk.UnisizeBanner? = null
    private var ciWebView: jp.co.makip.unisizesdk.UnisizeBanner? = null

    // 【検証用】unisizeバナーに渡す値（dev用）
    // （cid：クライアントID、itm：商品ID、cuid：ECサイト（アプリ）側のユーザーID）
    private var cid: String = ""
    private var itm: String = ""
    private var cuid: String = ""
    private var lang: String = ""

    // バナーにカスタムスタイルを適用（v1.2）
    private var customStyle: String =
        """
        
        """.trimIndent()

    private val sdkBnrMode =
        listOf(
            jp.co.makip.unisizesdk.UnisizeBanner.BannerType.TEXT,
            jp.co.makip.unisizesdk.UnisizeBanner.BannerType.EX,
        )

    override fun onViewCreated(
        view: View,
        savedInstanceState: Bundle?,
    ) {
        super.onViewCreated(view, savedInstanceState)

        textWebView = view.findViewById(R.id.textWebView)
        exWebView = view.findViewById(R.id.exWebView)
        ciWebView = view.findViewById(R.id.ciWebView)

        setupTextWebView() // textWebViewのセットアップ
        setupCiWebView() // ciWebViewのセットアップ
        setupButtons(view) // ボタンのセットアップ
    }

    // TextWebViewをセットアップするメソッド
    private fun setupTextWebView() {
        textWebView.listener =
            object : jp.co.makip.unisizesdk.UnisizeBannerListener {
                override fun didFinish() {
                    Log.d("MainActivity", "textWebView didFinish()")
                    setupExWebView() // ExWebViewをセットアップして表示
                }

                override fun didFail(unisizeError: jp.co.makip.unisizesdk.UnisizeError) {
                    val message = unisizeError.errMessage()
                    Log.d("MainActivity", "textWebView didFail($message)")
                    requireActivity().runOnUiThread {
                        textWebView.layoutParams.height = 0 // 高さを0に設定
                        textWebView.requestLayout()
                    }
                }

                override fun didResized(
                    width: Int,
                    height: Int,
                ) {
                    Log.d("MainActivity", "textWebView didResized(width：$width、height：$height)")
                    requireActivity().runOnUiThread {
                        textWebView.layoutParams.height = height
                        textWebView.requestLayout()
                    }
                }

                override fun bannerClicked() {
                    Log.d("MainActivity", "textWebView bannerClicked()")
                }

                override fun didUnsupported(message: String) {
                    Log.d("MainActivity", "textWebView didUnsupported($message)")
                    requireActivity().runOnUiThread {
                        textWebView.layoutParams.height = 0 // 高さを0に設定
                        textWebView.requestLayout()
                    }
                }

                override fun didBeidChanged(
                    beid: String,
                    recommendedItems: String,
                    type: String,
                ) {
                    Log.d("MainActivity", "textWebView didBeidChanged(beid: $beid, recommendedItems: $recommendedItems)")
                }
            }

        // UnisizeBannerのパラメータを設定
        textWebView.setupParam(
            bannerType = jp.co.makip.unisizesdk.UnisizeBanner.BannerType.TEXT,
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

        textWebView.addInterfaceToJavaScript(requireContext())
        textWebView.show() // バナーを表示
    }

    // ExWebViewをセットアップして表示するメソッド
    private fun setupExWebView() {
        exWebView?.listener =
            object : jp.co.makip.unisizesdk.UnisizeBannerListener {
                override fun didFinish() {
                    Log.d("MainActivity", "exWebView didFinish()")
                }

                override fun didFail(unisizeError: jp.co.makip.unisizesdk.UnisizeError) {
                    val message = unisizeError.errMessage()
                    Log.d("MainActivity", "exWebView didFail($message)")
                    requireActivity().runOnUiThread {
                        exWebView?.layoutParams?.height = 0 // 高さを0に設定
                        exWebView?.requestLayout()
                    }
                }

                override fun didResized(
                    width: Int,
                    height: Int,
                ) {
                    Log.d("MainActivity", "exWebView didResized(width：$width、height：$height)")
                    requireActivity().runOnUiThread {
                        exWebView?.layoutParams?.height = height
                        exWebView?.requestLayout()
                    }
                }

                override fun bannerClicked() {
                    Log.d("MainActivity", "exWebView bannerClicked()")
                }

                override fun didUnsupported(message: String) {
                    Log.d("MainActivity", "exWebView didUnsupported($message)")
                    requireActivity().runOnUiThread {
                        exWebView?.layoutParams?.height = 0 // 高さを0に設定
                        exWebView?.requestLayout()
                    }
                }

                override fun didBeidChanged(
                    beid: String,
                    recommendedItems: String,
                    type: String,
                ) {
                    Log.d("MainActivity", "exWebView didBeidChanged(beid: $beid, recommendedItems: $recommendedItems)")
                }
            }

        // UnisizeBannerのパラメータを設定
        exWebView?.setupParam(
            jp.co.makip.unisizesdk.UnisizeBanner.BannerType.EX,
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

        exWebView?.addInterfaceToJavaScript(requireContext())
        exWebView?.show() // バナーを表示
    }

    // CiWebViewをセットアップして表示するメソッド
    private fun setupCiWebView() {
        ciWebView?.listener =
            object : jp.co.makip.unisizesdk.UnisizeBannerListener {
                override fun didFinish() {
                    Log.d("MainActivity", "ciWebView didFinish")
                }

                override fun didFail(unisizeError: jp.co.makip.unisizesdk.UnisizeError) {
                    val message = unisizeError.errMessage()
                    Log.d("MainActivity", "ciWebView didFail：$message")
                    requireActivity().runOnUiThread {
                        ciWebView?.layoutParams?.height = 0 // 高さを0に設定
                        ciWebView?.requestLayout()
                    }
                }

                override fun didResized(
                    width: Int,
                    height: Int,
                ) {
                    Log.d("MainActivity", "ciWebView didResized：width：$width、height：$height")
                    requireActivity().runOnUiThread {
                        ciWebView?.layoutParams?.height = height
                        ciWebView?.requestLayout()
                    }
                }

                override fun bannerClicked() {
                    Log.d("MainActivity", "ciWebView bannerClicked")
                }

                override fun didUnsupported(message: String) {
                    Log.d("MainActivity", "ciWebView didUnsupported：$message")
                    requireActivity().runOnUiThread {
                        ciWebView?.layoutParams?.height = 0 // 高さを0に設定
                        ciWebView?.requestLayout()
                    }
                }

                override fun didBeidChanged(
                    beid: String,
                    recommendedItems: String,
                    type: String,
                ) {
                    Log.d("MainActivity", "ciWebView didBeidChanged(beid: $beid, recommendedItems: $recommendedItems)")
                }
            }

        // UnisizeBannerのパラメータを設定
        ciWebView?.setupParam(
            jp.co.makip.unisizesdk.UnisizeBanner.BannerType.CI,
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

        ciWebView?.addInterfaceToJavaScript(requireContext())
        ciWebView?.show() // バナーを表示
    }

    // ボタンのセットアップメソッド
    private fun setupButtons(view: View) {
        val itm_edit = view.findViewById<View>(R.id.itm) as EditText
        val cid_edit = view.findViewById<View>(R.id.cid) as EditText
        val cuid_edit = view.findViewById<View>(R.id.cuid) as EditText
        val lang_edit = view.findViewById<View>(R.id.lang) as EditText

        view.findViewById<Button>(R.id.reloadButton).setOnClickListener {
            if (textWebView != null) {
                Log.d("reload", "TEXT")
                textWebView.reload() // TextWebViewをリロード
            }

            if (exWebView != null) {
                Log.d("reload", "EX")
                exWebView!!.reload() // ExWebViewをリロード
            }

            if (ciWebView != null) {
                Log.d("reload", "CI")
                ciWebView!!.reload() // ExWebViewをリロード
            }
        }

        view.findViewById<Button>(R.id.showCVTagTestButton).setOnClickListener {
            val intent = Intent(requireContext(), CVTagTestActivity::class.java)
            startActivity(intent) // CVTagTestActivityを起動
        }

        view.findViewById<Button>(R.id.setParamButton).setOnClickListener {
            itm = itm_edit.getText().toString()
            cid = cid_edit.getText().toString()
            cuid = cuid_edit.getText().toString()
            lang = lang_edit.getText().toString()

            if (itm == "" || cid == "") {
                Toast
                    .makeText(requireContext(), "itm、またはcidが未設定です", Toast.LENGTH_SHORT)
                    .show()
                return@setOnClickListener
            }

            val bnrModeStr =
                sdkBnrMode
                    .stream()
                    .map { obj: BannerType -> obj.name }
                    .collect(Collectors.joining(","))

            Log.d("test", bnrModeStr)

            // アイテムIDなどのパラメーターの受け渡し

            // アイテムIDなどのパラメーターの受け渡し
            if (bnrModeStr == "TEXT" || bnrModeStr == "TEXT,EX") {
                textWebView.setupParam(
                    BannerType.TEXT,
                    sdkBnrMode,
                    itm,
                    cid,
                    cuid,
                    lang,
                    true,
                    true,
                    true,
                    customStyle,
                )
                // Javascriptからネイティブ関数を呼び出すためのインターフェース
                textWebView.addInterfaceToJavaScript(requireContext())
                // TEXTバナーを表示
                textWebView.show()
            }

            if (bnrModeStr == "EX" || bnrModeStr == "TEXT,EX") {
                exWebView!!.setupParam(
                    BannerType.EX,
                    sdkBnrMode,
                    itm,
                    cid,
                    cuid,
                    lang,
                    true,
                    true,
                    true,
                    customStyle,
                )
                // Javascriptからネイティブ関数を呼び出すためのインターフェース
                exWebView!!.addInterfaceToJavaScript(requireContext())
                // EXバナーを表示
                exWebView!!.show()
            }

            // アイテムIDなどのパラメーターの受け渡し

            // アイテムIDなどのパラメーターの受け渡し
            if (ciWebView != null) {
                ciWebView!!.setupParam(
                    BannerType.CI,
                    sdkBnrMode,
                    itm,
                    cid,
                    cuid,
                    lang,
                    true,
                    true,
                    true,
                    customStyle,
                )
                // Javascriptからネイティブ関数を呼び出すためのインターフェース
                ciWebView!!.addInterfaceToJavaScript(requireContext())
                // CIバナーを表示
                ciWebView!!.show()
            }
        }
    }
}
