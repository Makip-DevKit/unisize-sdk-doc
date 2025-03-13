//
//  ViewController.swift
//  unisizeSDK Sample App
//

import UIKit
import WebKit
import unisizeSDK

/*
    CvTagTestViewController class
*/
class CvTagTestViewController: UIViewController {
    
    @IBOutlet weak var cvTagRect: UIView!
    @IBOutlet weak var reloadBtn: UIButton!
    
    var unisizeCvTag: UnisizeCVTag!
    
    /*
        CvTagTestViewController > viewDidLoad
    */
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 初期化パラメータの定義
        let cid: String = ""  // クライアントID（makip発行のクライアント個別ID）
        let cuid: String = "" // クライアント会員ID（ユーザーを識別する固有ID）
        let purchaseid: String = "" // 購入ID（注文時に発行される固有ID）
        let itemnum: [String] = [] // 購入数（商品ごとにString配列で渡します。）
        let itemid: [String] = [] // アイテム識別ID（商品ごとにString配列で渡します。）
        let price: [String] = [] // 価格（商品ごとにString配列で渡します。）
        let size: [String] = [] // サイズ（商品ごとにString配列で渡します。）
        let iteminfo: String = "" // itemnum、itemid、price、sizeを1つにまとめたデータで送信する場合
        let iteminfojson: String = "" // itemnum、itemid、price、sizeを1つにまとめたJSONデータで送信する場合
        let regType: String = ""
        
        // String配列からCVタグが受け取れる形式に変換（「#」区切り）
        let itemnumString = itemnum.joined(separator: "%23")
        let itemidString = itemid.joined(separator: "%23")
        let priceString = price.joined(separator: "%23")
        let sizeString = size.joined(separator: "%23")
       
        // UnisizeCVTagのインスタンス生成
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
        
        // cvTagRectの位置に配置
        cvTagRect.addSubview(unisizeCvTag)
    }
    
    /*
        CVタグのWebViewのリロード（検証用）
    */
    @IBAction func reloadWebView(_ sender: Any) {
        unisizeCvTag.reloadWebView()
    }
    
    // 閉じるボタンがタップされたときのアクション
    @IBAction func closeButtonTapped(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        unisizeCvTag.removeFromSuperview()
        unisizeCvTag = nil
    }
}

/*
    UnisizeCVTagDelegate
*/
extension CvTagTestViewController: UnisizeCVTagDelegate {

    // コンポーネントの処理完了時に実行される
    func unisizeCVTag(_ cvTag: UnisizeCVTag, didFinish message: String) {
        print(message)
    }
    
    // コンポーネントの処理失敗時に実行される
    func unisizeCVTag(_ cvTag: UnisizeCVTag, didFail errorObj: UnisizeError) {
        print(errorObj.getJsonString())
    }
    
    // WebViewのバナー表示時に毎回通知（リロードでも呼び出される）
    func unisizeCVTag(_ cvTag: UnisizeCVTag, didLoaded message: String) {
        print(message)
    }
}
