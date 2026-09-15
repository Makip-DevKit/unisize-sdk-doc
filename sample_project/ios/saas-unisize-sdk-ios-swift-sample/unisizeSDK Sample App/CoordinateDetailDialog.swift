import UIKit
import unisizeSDK

/*
 * コーデ 1 件の取得内容を確認するための検証用ダイアログです。
 *
 * aunn テスト画面（AunnCoordinateTestViewController / AunnCoordinateWithUnisizeTestViewController）のコーデセル
 * 長押しから開き、API から取得した全項目をアラートに表示するとともに、同じ内容をコンソールへ
 * ダンプします。受入テストで画面ごとに確認できる項目がずれないよう、生成処理をここへ集約しています。
 * Android 版 CoordinateDetailDialog.kt に相当します。
 */
enum CoordinateDetailDialog {

    /// item の詳細をアラート表示し、コンソールにも出力します。
    /// tag は呼び出し元画面のログ接頭辞です（画面ごとに絞り込めるようにするため受け取ります）。
    static func show(from viewController: UIViewController, tag: String, item: AunnCoordinateItem) {
        let detail = buildDetail(item)
        print("\(tag) > coordinate detail:\n\(detail)")
        let alert = UIAlertController(title: "コーデ #\(item.id) 詳細", message: detail, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "閉じる", style: .default))
        viewController.present(alert, animated: true)
    }

    private static func buildDetail(_ item: AunnCoordinateItem) -> String {
        return """
        id: \(item.id)
        size: \(item.size)
        imgUrl: \(item.imgUrl)
        hasVideo: \(item.hasVideo)
        --- staff ---
        id/code: \(item.staff.id) / \(item.staff.code)
        name: \(item.staff.name)
        height: \(item.staff.height)
        bodyType: \(item.staff.bodyType ?? "nil")
        personalColor: \(item.staff.personalColor ?? "nil")
        imgUrl: \(item.staff.imgUrl)
        --- brand ---
        \(item.brand.id) / \(item.brand.code) / \(item.brand.name)
        --- shop ---
        \(item.shop.id) / \(item.shop.code) / \(item.shop.name)
        \(buildDebugInfoSection(item))
        """
    }

    /// レコメンド根拠（API レスポンスの `v`）の表示部分を生成します。
    /// 項目名と並び順は Web 版の検証サイトのデバッグ表示に合わせています。
    ///
    /// `v` は開発・QA 環境でのみ返るため、本番向けビルドでは「なし」と表示されます。
    /// また商品詳細系のページでは登録時刻と L2 ノルムのみが返り、協調フィルタリング由来の
    /// 項目は nil になります（その場合は "-" と表示します）。
    private static func buildDebugInfoSection(_ item: AunnCoordinateItem) -> String {
        let header = "--- v（レコメンド根拠）---"
        guard let debugInfo = item.debugInfo else {
            return "\(header)\nなし（開発・QA 環境でのみ返ります）"
        }
        return """
        \(header)
        登録時刻: \(describe(debugInfo.publishedAt))
        L2ノルム: \(describe(debugInfo.l2NormDiff))
        協調フィルタリングスコア: \(describe(debugInfo.collaborativeScore))
        協調フィルタリング追加スコア: \(describe(debugInfo.collaborativeExtraScore))
        身長区分差: \(describe(debugInfo.sectionDiff))
        """
    }

    /// 返らなかった項目は Android 版と同じく "-" で表します。
    private static func describe(_ value: String?) -> String {
        guard let value = value else { return "-" }
        return value
    }

    private static func describe(_ value: Double?) -> String {
        guard let value = value else { return "-" }
        return String(value)
    }
}
