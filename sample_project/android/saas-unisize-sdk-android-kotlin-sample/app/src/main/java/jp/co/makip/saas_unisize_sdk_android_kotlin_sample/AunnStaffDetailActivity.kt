package jp.co.makip.saas_unisize_sdk_android_kotlin_sample

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinatePageType
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateTracking
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateTrackingParam

/**
 * aunn スタッフ画面です（コーディネート一覧のスタッフアイコンタップから遷移する検証用画面）。
 *
 * 遷移元から渡された cid / cuid / staffId / スタッフ写真を表示し、表示完了時に
 * スタッフの View 計測（page=staff）を送信します。
 * cuid の有無でレコメンドの種別が変わるため、遷移元の入力値をそのまま引き継いで計測に載せます。
 */
class AunnStaffDetailActivity : AppCompatActivity() {
    companion object {
        private const val EXTRA_CID = "cid"
        private const val EXTRA_CUID = "cuid"
        private const val EXTRA_STAFF_ID = "staffId"
        private const val EXTRA_STAFF_IMG_URL = "staffImgUrl"

        /** [cuid] は遷移元で未入力なら null を渡します（未入力のときは計測に載せません）。 */
        fun createIntent(
            context: Context,
            cid: String,
            cuid: String?,
            staffId: Int,
            staffImgUrl: String,
        ): Intent =
            Intent(context, AunnStaffDetailActivity::class.java)
                .putExtra(EXTRA_CID, cid)
                .putExtra(EXTRA_CUID, cuid)
                .putExtra(EXTRA_STAFF_ID, staffId)
                .putExtra(EXTRA_STAFF_IMG_URL, staffImgUrl)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val cid = intent.getStringExtra(EXTRA_CID).orEmpty()
        // cuid は未指定（null）と空文字を区別せず、どちらも「送信しない」として扱います
        val cuid = intent.getStringExtra(EXTRA_CUID)?.ifEmpty { null }
        val staffId = intent.getIntExtra(EXTRA_STAFF_ID, 0)
        val staffImgUrl = intent.getStringExtra(EXTRA_STAFF_IMG_URL).orEmpty()

        title = "aunn スタッフ"
        setContentView(buildLayout(cid, cuid, staffId, staffImgUrl))

        // 表示完了時にスタッフの View 計測を送信します（回転などの再生成時は重複送信を抑止）
        if (savedInstanceState == null) {
            AunnCoordinateTracking(this).apply {
                setupParam(
                    AunnCoordinateTrackingParam(
                        cid = cid,
                        pageType = AunnCoordinatePageType.STAFF,
                        cuid = cuid,
                        staffId = staffId,
                        enablePrintLog = true,
                    ),
                )
                send()
            }
        }
    }

    private fun buildLayout(
        cid: String,
        cuid: String?,
        staffId: Int,
        staffImgUrl: String,
    ): ScrollView {
        val root =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(24, 24, 24, 24)
            }
        root.addView(
            ImageView(this).apply {
                adjustViewBounds = true
                contentDescription = "スタッフ #$staffId"
                layoutParams =
                    LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    )
                SampleImageLoader.load(staffImgUrl, this)
            },
        )
        root.addView(
            TextView(this).apply {
                text =
                    buildString {
                        appendLine("cid: $cid")
                        appendLine("cuid: ${cuid ?: "（未送信）"}")
                        appendLine("staffId: $staffId")
                        append("imgUrl: $staffImgUrl")
                    }
                setPadding(0, 16, 0, 0)
            },
        )
        return ScrollView(this).apply { addView(root) }
    }
}
