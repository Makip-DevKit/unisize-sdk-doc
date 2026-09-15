package jp.co.makip.saas_unisize_sdk_android_kotlin_sample

import android.app.Activity
import android.util.Log
import androidx.appcompat.app.AlertDialog
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateItem

/**
 * コーディネート 1 件の取得内容を確認するための検証用ダイアログです。
 *
 * aunn テスト画面（[AunnCoordinateTestActivity] / [AunnCoordinateWithUnisizeTestActivity]）のコーディネートセル長押しから開き、
 * API から取得した全項目をダイアログに表示するとともに、同じ内容を Logcat へダンプします。
 * 受入テストで画面ごとに確認できる項目がずれないよう、生成処理をここへ集約しています。
 */
object AunnCoordinateItemDebugDialog {
    /**
     * [item] の詳細をダイアログ表示し、Logcat にも出力します。
     * [tag] は呼び出し元画面の Logcat タグです（画面ごとに絞り込めるようにするため受け取ります）。
     */
    fun show(
        activity: Activity,
        tag: String?,
        item: AunnCoordinateItem,
    ) {
        val detail = buildDetail(item)
        Log.d(tag, "coordinate detail:\n$detail")
        AlertDialog
            .Builder(activity)
            .setTitle("コーディネート #${item.id} 詳細")
            .setMessage(detail)
            .setPositiveButton("閉じる", null)
            .show()
    }

    private fun buildDetail(item: AunnCoordinateItem): String =
        buildString {
            appendLine("id: ${item.id}")
            appendLine("size: ${item.size}")
            appendLine("imgUrl: ${item.imgUrl}")
            appendLine("hasVideo: ${item.hasVideo}")
            appendLine("--- staff ---")
            appendLine("id/code: ${item.staff.id} / ${item.staff.code}")
            appendLine("name: ${item.staff.name}")
            appendLine("height: ${item.staff.height}")
            appendLine("bodyType: ${item.staff.bodyType}")
            appendLine("personalColor: ${item.staff.personalColor}")
            appendLine("imgUrl: ${item.staff.imgUrl}")
            appendLine("--- brand ---")
            appendLine("${item.brand.id} / ${item.brand.code} / ${item.brand.name}")
            appendLine("--- shop ---")
            appendLine("${item.shop.id} / ${item.shop.code} / ${item.shop.name}")
            append(buildDebugInfoSection(item))
        }

    /**
     * レコメンド根拠（API レスポンスの `v`）の表示部分を生成します。
     * 項目名と並び順は Web 版の検証サイトのデバッグ表示に合わせています。
     *
     * `v` は開発・QA 環境でのみ返るため、本番向けビルドでは「なし」と表示されます。
     * また商品詳細系のページでは登録時刻と L2 ノルムのみが返り、協調フィルタリング由来の
     * 項目は null になります（その場合は "-" と表示します）。
     */
    private fun buildDebugInfoSection(item: AunnCoordinateItem): String =
        buildString {
            appendLine("--- v（レコメンド根拠）---")
            val debugInfo = item.debugInfo
            if (debugInfo == null) {
                appendLine("なし（開発・QA 環境でのみ返ります）")
                return@buildString
            }
            appendLine("登録時刻: ${debugInfo.publishedAt ?: "-"}")
            appendLine("L2ノルム: ${debugInfo.l2NormDiff ?: "-"}")
            appendLine("協調フィルタリングスコア: ${debugInfo.collaborativeScore ?: "-"}")
            appendLine("協調フィルタリング追加スコア: ${debugInfo.collaborativeExtraScore ?: "-"}")
            appendLine("身長区分差: ${debugInfo.sectionDiff ?: "-"}")
        }
}
