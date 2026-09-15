import UIKit
import WebKit
import unisizeSDK

// MARK: - CvTagTestViewController（CVタグの実装サンプル）
/*
 * UnisizeCVTag を使って購入完了（コンバージョン）を計測する検証用画面です。
 *
 * 購入完了ページ（サンクスページ）相当の画面で UnisizeCVTag を生成し、任意の View へ addSubview すると、
 * 画面表示のタイミングで CV タグが発火して購入情報が送信されます。
 *
 * 実装の流れは次の 3 ステップです。
 *  1. 購入情報（cid / cuid / purchaseid と商品ごとの itemnum・itemid・price・size）を用意する
 *  2. 商品ごとのパラメータは複数商品を "%23"（# のURLエンコード）で連結した文字列にする
 *  3. UnisizeCVTag を生成して表示領域へ addSubview する（画面を閉じるときは close() で破棄する）
 *
 * ※ 送信内容は実際に購入として集計されます。動作確認は unisize が発行した
 *   テスト用クライアント識別ID（CID）を使用して下さい。
 */
class CvTagTestViewController: UIViewController {
    
    // MARK: - IBOutlet（Storyboard接続）
    @IBOutlet weak var cvTagRect: UIView!     // CVタグの表示領域
    @IBOutlet weak var reloadBtn: UIButton!   // リロードボタン
    
    // MARK: - UnisizeCVTag インスタンス
    var unisizeCvTag: UnisizeCVTag!
    
    // MARK: - ライフサイクル
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // --- ▼ 初期化用パラメータ定義 ▼ ---
        let cid: String = "" // クライアントID
        let cuid: String = "" // ECサイトのユーザー識別ID
        let purchaseid: String = ""  // 購入ID

        // 商品ごとのパラメータ（String配列）
        let itemnum: [String] = [] // 商品ごとの購入数
        let itemid: [String] = [] // 商品識別ID（商品ごと）
        let price: [String] = [] // 商品ごとの価格
        let size: [String] = [] // サイズ情報（商品ごと）

        // iteminfo形式（まとめて送信する場合用）
        let iteminfo: String = "" // ※通常は使用しない
        let iteminfojson: String = "" // ※通常は使用しない
        let regType: String = "" // ※通常は使用しない
        // --- ▲ 初期化用パラメータ定義 ▲ ---

        // 商品ごとのパラメータは、商品の並び順を揃えたうえで
        // "%23"（# のURLエンコード）区切りの1つの文字列に連結して渡します。
        // 例: itemid = ["A", "B"] → "A%23B"
        let itemnumString = itemnum.joined(separator: "%23")
        let itemidString = itemid.joined(separator: "%23")
        let priceString = price.joined(separator: "%23")
        let sizeString = size.joined(separator: "%23")
       
        // MARK: - UnisizeCVTagのインスタンス生成と設定
        unisizeCvTag = UnisizeCVTag(
            cvTagRect: cvTagRect,
            cid: cid,
            cuid: cuid,
            purchaseid: purchaseid,
            itemnum: itemnumString,
            itemid: itemidString,
            price: priceString,
            size: sizeString,
            iteminfo: iteminfo,
            iteminfojson: iteminfojson,
            regType: regType,
            enableWebViewLog: true,
            enablePrintLog: true,
            sendErrorLog: true,
            delegate: self
        )
        
        // cvTagRectにUnisizeCVTagを追加
        cvTagRect.addSubview(unisizeCvTag)
    }
    
    // MARK: - アクション（ボタン）

    /// WebViewをリロード（検証用）
    @IBAction func reloadWebView(_ sender: Any) {
        unisizeCvTag.reloadWebView()
    }
    
    /// 閉じるボタンタップ時にモーダルを閉じる
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - モーダルの破棄時処理（メモリ開放）
    // WebView が残らないよう、画面を閉じるときに必ず close() を呼んで破棄して下さい。
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        
        // UnisizeCVTagの後処理
        unisizeCvTag.removeFromSuperview()
        unisizeCvTag.close()
        unisizeCvTag = nil
    }
}

// MARK: - UnisizeCVTagDelegate 実装
extension CvTagTestViewController: UnisizeCVTagDelegate {

    /// CVタグの処理完了時に呼ばれる
    func unisizeCVTag(_ cvTag: UnisizeCVTag, didFinish message: String) {
        print(message)
    }
    
    /// CVタグの処理失敗時に呼ばれる
    func unisizeCVTag(_ cvTag: UnisizeCVTag, didFail errorObj: UnisizeError) {
        print(errorObj.getJsonString())
    }
    
    /// WebViewバナーのロード完了時に毎回呼ばれる（リロード時含む）
    func unisizeCVTag(_ cvTag: UnisizeCVTag, didLoaded message: String) {
        print(message)
    }
}
