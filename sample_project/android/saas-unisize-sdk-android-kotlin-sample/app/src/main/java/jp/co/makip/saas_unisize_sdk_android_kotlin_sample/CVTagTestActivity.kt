package jp.co.makip.saas_unisize_sdk_android_kotlin_sample

import android.os.Bundle
import android.util.Log
import android.widget.Button
import androidx.activity.enableEdgeToEdge
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat

class CVTagTestActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContentView(R.layout.activity_cvtag_test_activity)

        // UnisizeCVTag（WKWebView）の初期化と設定
        // Javascriptに渡す値（※検証用のサンプルデータ）
        val cid: String = ""  // クライアントID
        val cuid: String = "" // ECサイトの会員ID
        val purchaseid: String = "" // 購入時に発行された注文ID
        val itemnum: List<String> = listOf("") // 購入数（アイテム毎）
        val itemid: List<String> = listOf("") // 購入アイテムのアイテムID
        val price: List<String> = listOf("") // 購入アイテムの金額（アイテム毎）
        val size: List<String> = listOf("") // 購入したアイテムのサイズ（アイテム毎）
        val iteminfo: String = ""
        val regType: String = ""

        var cvTagWebView: jp.co.makip.unisizesdk.UnisizeCVTag = findViewById(R.id.cvTagWebView)
        cvTagWebView.listener = object : jp.co.makip.unisizesdk.UnisizeCVTagListener {
            // 読み込み完了時に実行したい処理を実装
            override fun didFinish() {
                Log.d("UnisizeCVTag", "didFinish()")
            }

            // エラーが発生した場合に実行したい処理を記述
            override fun didFail(unisizeError: jp.co.makip.unisizesdk.UnisizeError) {
                // エラーが発生した場合の処理
                val message = unisizeError.errMessage()
                Log.d("UnisizeCVTag", "didFail(${message})")
            }
        }

        cvTagWebView.setupParam(
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
            true
        )

        cvTagWebView.show()

        // WebViewリロードボタン（通信検証用）
        val reloadButton: Button = findViewById(R.id.reloadButton)
        reloadButton.setOnClickListener {
            cvTagWebView.reload()
        }

        val closeButton: Button = findViewById(R.id.closeButton)
        closeButton.setOnClickListener {
            finish() // 現在のアクティビティを閉じる
        }

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main)) { v, insets ->
            val systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars())
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom)
            insets
        }

    }
}