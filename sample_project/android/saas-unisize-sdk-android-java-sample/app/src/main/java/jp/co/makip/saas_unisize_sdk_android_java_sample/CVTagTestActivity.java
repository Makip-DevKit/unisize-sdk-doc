package jp.co.makip.saas_unisize_sdk_android_java_sample;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import java.util.Arrays;
import java.util.List;

public class CVTagTestActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_cvtag_test_activity);

        // UnisizeCVTag（WKWebView）の初期化と設定
        // Javascriptに渡す値（※検証用のサンプルデータ）
        String cid = "";  // クライアントID
        String cuid = ""; // ECサイトの会員ID
        String purchaseid = ""; // 購入時に発行された注文ID
        List<String> itemnum = Arrays.asList("", ""); // 購入数（アイテム毎）
        List<String> itemid = Arrays.asList("", ""); // 購入アイテムのアイテムID
        List<String> price = Arrays.asList("", ""); // 購入アイテムの金額（アイテム毎）
        List<String> size = Arrays.asList("", ""); // 購入したアイテムのサイズ（アイテム毎）
        String iteminfo = "";
        String regType = "";

        jp.co.makip.unisizesdk.UnisizeCVTag cvTagWebView = findViewById(R.id.cvTagWebView);
        cvTagWebView.setListener(new jp.co.makip.unisizesdk.UnisizeCVTagListener() {
            // 読み込み完了時に実行したい処理を実装
            @Override
            public void didFinish() {
                Log.d("UnisizeCVTag", "didFinish()");
            }

            // エラーが発生した場合に実行したい処理を記述
            @Override
            public void didFail(jp.co.makip.unisizesdk.UnisizeError unisizeError) {
                // エラーが発生した場合の処理
                String message = unisizeError.errMessage();
                Log.d("UnisizeCVTag", "didFail(" + message + ")");
            }
        });

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
        );

        cvTagWebView.show();

        // WebViewリロードボタン（通信検証用）
        Button reloadButton = findViewById(R.id.reloadButton);
        reloadButton.setOnClickListener(v -> cvTagWebView.reload());

        Button closeButton = findViewById(R.id.closeButton);
        closeButton.setOnClickListener(v -> finish()); // 現在のアクティビティを閉じる

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), new androidx.core.view.OnApplyWindowInsetsListener() {
            @Override
            public WindowInsetsCompat onApplyWindowInsets(View v, WindowInsetsCompat insets) {
                int left = insets.getInsets(WindowInsetsCompat.Type.systemBars()).left;
                int top = insets.getInsets(WindowInsetsCompat.Type.systemBars()).top;
                int right = insets.getInsets(WindowInsetsCompat.Type.systemBars()).right;
                int bottom = insets.getInsets(WindowInsetsCompat.Type.systemBars()).bottom;
                v.setPadding(left, top, right, bottom);
                return insets;
            }
        });
    }

}
