import UIKit
import WebKit
import unisizeSDK

// MARK: - CvTagTestViewController（CVタグ検証用画面）
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

        // String配列をCVタグが扱える形式に変換（#で区切る）
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
