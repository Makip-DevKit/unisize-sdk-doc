//
//  ViewController.swift
//  unisizeSDK Sample App
//

import UIKit
import WebKit
import unisizeSDK // unisizeSDK

/*
    Main.storyboardの ViewController class
*/
class ViewController: UIViewController {
    // UnisizeBanner インスタンス
    var unisizeBanner: UnisizeBanner!
    
    // IBOutlet変数
    @IBOutlet weak var textBannerRect: UIView!
    @IBOutlet weak var exBannerRect: UIView!
    @IBOutlet weak var ciBannerRect: UIView!
    @IBOutlet weak var bannerLabel: UILabel!
    @IBOutlet weak var itmTextField: UITextField!
    @IBOutlet weak var cidTextField: UITextField!
    @IBOutlet weak var cuidTextField: UITextField!
    @IBOutlet weak var langTextField: UITextField!
    
    // unisizeBanner 用パラメーター
    var cid: String = "" // クライアントID
    var itm: String = "" // アイテム識別ID
    var cuid: String = "" // クライアント会員ID
    var lang: String = "" // 表示言語(オプション)
    
    // バナーにカスタムスタイル（css）を適用（v1.2から利用可能）
    // ※ 付属のドキュメントをご確認ください。
    var customStyle: String = ""
    
    // NSLayoutConstraint 変数
    var textBannerRectHeightConstraint: NSLayoutConstraint!
    var exBannerRectHeightConstraint: NSLayoutConstraint!
    var ciBannerRectHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // textBannerRect のレイアウト設定
        textBannerRect.translatesAutoresizingMaskIntoConstraints = false
        textBannerRectHeightConstraint = textBannerRect.heightAnchor.constraint(equalToConstant: 60)
        
        // exBannerRect のレイアウト設定
        exBannerRect.translatesAutoresizingMaskIntoConstraints = false
        exBannerRectHeightConstraint = exBannerRect.heightAnchor.constraint(equalToConstant: 180)
        
        ciBannerRect.translatesAutoresizingMaskIntoConstraints = false
        ciBannerRectHeightConstraint = ciBannerRect.heightAnchor.constraint(equalToConstant: 300)
        
        // NSLayoutConstraint の設定
        NSLayoutConstraint.activate([
            textBannerRect.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textBannerRect.topAnchor.constraint(equalTo: bannerLabel.bottomAnchor, constant: 16),
            textBannerRect.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            textBannerRect.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            textBannerRectHeightConstraint,
            exBannerRect.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            exBannerRect.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            exBannerRect.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            exBannerRectHeightConstraint,
            ciBannerRect.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ciBannerRect.topAnchor.constraint(equalTo: exBannerRect.bottomAnchor, constant: 16),
            ciBannerRect.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            ciBannerRect.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            ciBannerRectHeightConstraint
        ])
        
        // unisizeBanner の初期化とセットアップ
        unisizeBanner = UnisizeBanner(
            textBannerRect: textBannerRect, // TEXT バナー用の UIView を渡します
            exBannerRect: exBannerRect, // EX バナー用の UIView を渡します
            ciBannerRect: ciBannerRect, // CI バナー用の UIView を渡します
            parentView: self, // unisizeBanner を配置している ViewController を渡します
            cid: cid, // クライアントID
            itm: itm, // アイテム識別ID
            cuid: cuid, // クライアント会員ID
            lang: lang, // 表示言語
            enableWebViewLog: true, // webView の console.log を出力します
            enablePrintLog: true, // unisizeBanner class のログをコンソールへ出力します
            sendErrorLog: true, // エラー発生時にエラーログを unisize サーバーへ送信します
            delegate: self, // delegate
            customStyle: customStyle // バナーにカスタムスタイル（css）を適用（v1.2）
        )
    }
    
    // CVTagTestボタンがタップされたときのアクション
    @IBAction func cvTagTestTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let cvTagTestViewController = storyboard.instantiateViewController(withIdentifier: "CvTagTestViewControllerID") as? CvTagTestViewController {
            self.present(cvTagTestViewController, animated: true, completion: nil)
        }
    }
    
    // リロードボタンのアクション
    @IBAction func reloadButton(_ sender: Any) {
        unisizeBanner.reload()
    }
    
    // フォームの送信アクション
    @IBAction func formSend(_ sender: Any) {
        let cid = cidTextField.text ?? ""
        let itm = itmTextField.text ?? ""
        let cuid = cuidTextField.text ?? ""
        let lang = langTextField.text ?? ""
        
        unisizeBanner.setupParam(cid: cid, itm: itm, cuid: cuid, lang: lang)
    }
}

/*
    UnisizeBannerDelegate 実装
*/
extension ViewController: UnisizeBannerDelegate {

    // コンポーネントの処理完了時に実行される
    func unisizeBanner(_ banner: UnisizeBanner, didFinish message: String) {
        print("didFinish: message: \(message)")
    }
    
    // コンポーネントの処理失敗時に実行される
    func unisizeBanner(_ banner: UnisizeBanner, didFail errorObj: UnisizeError)  {
        print("didFail: \(errorObj.getJsonString())")
        
        // バナーを非表示（バナーのUIViewに制約を設定している場合）
        textBannerRectHeightConstraint.constant = 0
        textBannerRect.layoutIfNeeded()
        exBannerRectHeightConstraint.constant = 0
        exBannerRect.layoutIfNeeded()
        ciBannerRectHeightConstraint.constant = 0
        ciBannerRect.layoutIfNeeded()
    }
    
    // コンポーネントのリサイズ時に実行される
    func unisizeBanner(_ banner: UnisizeBanner, didResized message: String, width: CGFloat, height: CGFloat, viewType: String) {
        print("didResized: width: \(width) height: \(height) type: \(viewType)")
        
        // バナーを表示するための UIView をサイズ変更
        if viewType == "text_banner" {
            textBannerRectHeightConstraint.constant = height
            textBannerRect.layoutIfNeeded()
        } else if viewType == "ex_banner" {
            exBannerRectHeightConstraint.constant = height
            exBannerRect.layoutIfNeeded()
        } else if (viewType == "ci_banner") {
            ciBannerRectHeightConstraint.constant = height
            ciBannerRect.layoutIfNeeded()
        }
    }
    
    // WebView のバナー表示時に毎回通知（バナーのリロードが発生した場合も実行される）
    func unisizeBanner(_ banner: UnisizeBanner, didLoaded message: String, viewType: String) {
        print("didLoaded: message: \(message) type: \(viewType)")
    }
    
    // unisize 対象外商品の場合に呼び出される
    func unisizeBanner(_ banner: UnisizeBanner, didUnsupported message: String) {
        print("didUnsupported: \(message)")
        
        // バナーのUIViewを非表示（バナーのUIViewに制約を設定している場合）
        if (message == "all") {
            // TEXTバナーを非表示
            textBannerRectHeightConstraint.constant = 0
            textBannerRect.layoutIfNeeded()

            // EXバナーを非表示
            exBannerRectHeightConstraint.constant = 0
            exBannerRect.layoutIfNeeded()
        }
        
        // CIバナーを非表示
        ciBannerRectHeightConstraint.constant = 0
        ciBannerRect.layoutIfNeeded()
    }
    
    // beidが変更された場合に呼び出される
    func unisizeBanner(_ banner: UnisizeBanner, didBeidChanged beid: String, recommendedItems: String, type: String) {
        print("didBeidChanged: beid: \(beid) recommendedItems: \(recommendedItems) type: \(type)")
    }
}
