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
 * aunn コーディネート詳細画面です（コーディネート一覧の写真タップから遷移する検証用画面）。
 *
 * 遷移元から渡された cid / cuid / coordinateId / imgUrl / staffId を表示し、表示完了時に
 * コーディネート詳細の View 計測（page=coordination-detail）を送信します。
 * cuid の有無でレコメンドの種別が変わるため、遷移元の入力値をそのまま引き継いで計測に載せます。
 */
class AunnCoordinateDetailActivity : AppCompatActivity() {
    companion object {
        private const val EXTRA_CID = "cid"
        private const val EXTRA_CUID = "cuid"
        private const val EXTRA_COORDINATE_ID = "coordinateId"
        private const val EXTRA_IMG_URL = "imgUrl"
        private const val EXTRA_STAFF_ID = "staffId"

        /** [cuid] は遷移元で未入力なら null を渡します（未入力のときは計測に載せません）。 */
        fun createIntent(
            context: Context,
            cid: String,
            cuid: String?,
            coordinateId: Int,
            imgUrl: String,
            staffId: Int,
        ): Intent =
            Intent(context, AunnCoordinateDetailActivity::class.java)
                .putExtra(EXTRA_CID, cid)
                .putExtra(EXTRA_CUID, cuid)
                .putExtra(EXTRA_COORDINATE_ID, coordinateId)
                .putExtra(EXTRA_IMG_URL, imgUrl)
                .putExtra(EXTRA_STAFF_ID, staffId)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val cid = intent.getStringExtra(EXTRA_CID).orEmpty()
        // cuid は未指定（null）と空文字を区別せず、どちらも「送信しない」として扱います
        val cuid = intent.getStringExtra(EXTRA_CUID)?.ifEmpty { null }
        val coordinateId = intent.getIntExtra(EXTRA_COORDINATE_ID, 0)
        val imgUrl = intent.getStringExtra(EXTRA_IMG_URL).orEmpty()
        val staffId = intent.getIntExtra(EXTRA_STAFF_ID, 0)

        title = "aunn コーディネート詳細"
        setContentView(buildLayout(cid, cuid, coordinateId, imgUrl, staffId))

        // 表示完了時にコーディネート詳細の View 計測を送信します（回転などの再生成時は重複送信を抑止）
        if (savedInstanceState == null) {
            AunnCoordinateTracking(this).apply {
                setupParam(
                    AunnCoordinateTrackingParam(
                        cid = cid,
                        pageType = AunnCoordinatePageType.COORDINATE_DETAIL,
                        cuid = cuid,
                        coordinateId = coordinateId,
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
        coordinateId: Int,
        imgUrl: String,
        staffId: Int,
    ): ScrollView {
        val root =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(24, 24, 24, 24)
            }
        root.addView(
            ImageView(this).apply {
                adjustViewBounds = true
                contentDescription = "コーディネート #$coordinateId"
                layoutParams =
                    LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    )
                SampleImageLoader.load(imgUrl, this)
            },
        )
        root.addView(
            TextView(this).apply {
                text =
                    buildString {
                        appendLine("cid: $cid")
                        appendLine("cuid: ${cuid ?: "（未送信）"}")
                        appendLine("coordinateId: $coordinateId")
                        appendLine("staffId: $staffId")
                        append("imgUrl: $imgUrl")
                    }
                setPadding(0, 16, 0, 0)
            },
        )
        return ScrollView(this).apply { addView(root) }
    }
}
