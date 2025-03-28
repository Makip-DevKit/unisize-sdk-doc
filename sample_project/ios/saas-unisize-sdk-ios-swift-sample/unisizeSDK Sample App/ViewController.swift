import UIKit
import WebKit
import unisizeSDK

// MARK: - ViewController（Main.storyboardの ViewController）
class ViewController: UIViewController {
    
    // MARK: - IBOutlet変数（Storyboardと接続）
    @IBOutlet weak var textBannerWebview: UnisizeBannerWebview!
    @IBOutlet weak var exBannerWebview: UnisizeBannerWebview!
    @IBOutlet weak var ciBannerWebview: UnisizeBannerWebview!
    
    @IBOutlet weak var bannerLabel: UILabel!
    @IBOutlet weak var itmTextField: UITextField!
    @IBOutlet weak var cidTextField: UITextField!
    @IBOutlet weak var cuidTextField: UITextField!
    @IBOutlet weak var langTextField: UITextField!
    
    // MARK: - unisizeバナー用パラメータ
    var cid: String = "" // クライアントID
    var itm: String = "" // 商品識別ID
    var cuid: String = "" // ECサイトのユーザー識別ID
    var lang: String = "" // 表示言語（Default：ja）
    var enableWebViewLog: Bool = true // WebView内のconsole.logをXcodeに出力
    var enablePrintLog: Bool = true // SDKの内部ログ出力を有効化
    var sendErrorLog: Bool = true // エラーログ送信を有効化
    var customStyle: String = "" // カスタムCSS（非推奨）
    
    // MARK: - 高さ制約（各バナー用）
    var textBannerWebviewHeightConstraint: NSLayoutConstraint!
    var exBannerWebviewHeightConstraint: NSLayoutConstraint!
    var ciBannerWebviewHeightConstraint: NSLayoutConstraint!
    
    // MARK: - ライフサイクルメソッド
    override func viewDidLoad() {
        super.viewDidLoad()
        print("ViewController > viewDidLoad()")
        
        // WebViewのインスペクタ有効化（Safariでデバッグ可能）
        UserDefaults.standard.set(true, forKey: "WebKitDeveloperExtras")

        // 共通設定
        let bannerWebviews: [UnisizeBannerWebview?] = [textBannerWebview, exBannerWebview, ciBannerWebview]
        bannerWebviews.forEach { banner in
            banner?.translatesAutoresizingMaskIntoConstraints = false
        }

        // 各バナーの高さ制約（初期は非表示=高さ0）
        textBannerWebviewHeightConstraint = textBannerWebview?.heightAnchor.constraint(equalToConstant: 0)
        exBannerWebviewHeightConstraint = exBannerWebview?.heightAnchor.constraint(equalToConstant: 0)
        ciBannerWebviewHeightConstraint = ciBannerWebview?.heightAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            textBannerWebviewHeightConstraint,
            exBannerWebviewHeightConstraint,
            ciBannerWebviewHeightConstraint
        ])
        // ※左右にも制約を設定して横幅を確保しないと、横幅が0になってしまい、バナーが表示されない場合があります。
        
        // パラメータ設定
        createBannerParam()
        
        // バナーの表示
        // ※ TEXTバナー、EXバナー両方使用する場合は、キャッシュ利用の関係で、TEXTバナーの didFinish のタイミングでEXバナーを.show()してください。
        textBannerWebview?.show()
        ciBannerWebview?.show()
    }
    
    // ViewControllerを閉じるときの処理
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print("ViewController > viewWillDisappear")
        
        // 各バナーのリソース解放
        textBannerWebview?.close()
        exBannerWebview?.close()
        ciBannerWebview?.close()
        
        // 参照をnilにしてメモリ解放
        textBannerWebview = nil
        exBannerWebview = nil
        ciBannerWebview = nil
    }
    
    // MARK: - Unisizeバナー設定処理
    
    /// 各バナーのパラメータ生成と初期設定を行う
    func createBannerParam() {
        print("ViewController > createBannerParam()")
        
        let bannerTypes: [(UnisizeBannerWebview?, String)] = [
            (textBannerWebview, "text"),
            (exBannerWebview, "ex"),
            (ciBannerWebview, "ci")
        ]
        
        // CIバナーは bannerMode から除外
        let availableBannerTypes = bannerTypes.compactMap { banner, type in
            (banner != nil && type != "ci") ? type : nil
        }
        let bannerMode = availableBannerTypes.joined(separator: ",")
        
        // 各バナーへパラメータを設定
        bannerTypes.forEach { banner, type in
            if let banner = banner {
                setupBannerParam(banner: banner, bannerType: type, bannerMode: bannerMode)
            }
        }
    }

    /// 個別のUnisizeバナーへパラメータを設定
    func setupBannerParam(banner: UnisizeBannerWebview, bannerType: String, bannerMode: String) {
        print("ViewController > setupBannerParam()")
        print("bannerType:\(bannerType)")
        print("bannerMode:\(bannerMode)")
        
        banner.setupParam(
            parentView: self,
            bannerType: bannerType,
            bannerMode: bannerMode,
            cid: cid,
            itm: itm,
            cuid: cuid,
            lang: lang,
            enableWebViewLog: enableWebViewLog,
            enablePrintLog: enablePrintLog,
            sendErrorLog: sendErrorLog,
            delegate: self,
            customStyle: customStyle
        )
    }
    
    // MARK: - UIアクション（ボタン等）

    /// CVTagTest画面へ遷移
    @IBAction func cvTagTestTapped(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let cvTagTestViewController = storyboard.instantiateViewController(withIdentifier: "CvTagTestViewControllerID") as? CvTagTestViewController {
            self.present(cvTagTestViewController, animated: true, completion: nil)
        }
    }
    
    /// 各バナーのリロード処理
    @IBAction func reloadButton(_ sender: Any) {
        textBannerWebview?.reload()
        exBannerWebview?.reload()
        ciBannerWebview?.reload()
    }
    
    /// フォームから入力値を取得してバナー再表示
    @IBAction func formSend(_ sender: Any) {
        let cid = cidTextField.text ?? ""
        let itm = itmTextField.text ?? ""
        let cuid = cuidTextField.text ?? ""
        let lang = langTextField.text ?? ""
        
        self.cid = cid
        self.itm = itm
        self.cuid = cuid
        self.lang = lang
        
        createBannerParam()
        
        textBannerWebview?.show()
        ciBannerWebview?.show()
    }
}

// MARK: - UnisizeBannerWebviewDelegate実装
extension ViewController: UnisizeBannerWebviewDelegate {
    
    // 表示完了時
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didFinish message: String, bannerType: String) {
        print("didFinish: message: \(message)")
        
        // EXバナーはTEXTバナー完了後に.show()します。
        if (bannerType == "text") {
            exBannerWebview?.show()
        }
    }
    
    // 表示失敗時
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didFail errorObj: UnisizeError) {
        print("didFail: \(errorObj.getJsonString())")
        
        // 高さを0にして非表示にする
        textBannerWebviewHeightConstraint?.constant = 0
        textBannerWebview?.layoutIfNeeded()
        exBannerWebviewHeightConstraint?.constant = 0
        exBannerWebview?.layoutIfNeeded()
        ciBannerWebviewHeightConstraint?.constant = 0
        ciBannerWebview?.layoutIfNeeded()
    }
    
    // バナーのリサイズ時
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didResized message: String, width: CGFloat, height: CGFloat, bannerType: String) {
        print("didResized: width: \(width) height: \(height) bannerType: \(bannerType)")
        
        // 高さ制約を更新してサイズ変更
        if (bannerType == "text") {
            textBannerWebviewHeightConstraint.constant = height
            textBannerWebview.layoutIfNeeded()
        } else if (bannerType == "ex") {
            exBannerWebviewHeightConstraint?.constant = height
            exBannerWebview?.layoutIfNeeded()
        } else if (bannerType == "ci") {
            ciBannerWebviewHeightConstraint?.constant = height
            ciBannerWebview?.layoutIfNeeded()
        }
    }
    
    // unisize対象外の場合
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didUnsupported message: String) {
        print("didUnsupported: \(message)")
        
        // 高さを0にして非表示にする
        if (message == "all") {
            textBannerWebviewHeightConstraint?.constant = 0
            textBannerWebview?.layoutIfNeeded()
            exBannerWebviewHeightConstraint?.constant = 0
            exBannerWebview?.layoutIfNeeded()
        }
        
        ciBannerWebviewHeightConstraint?.constant = 0
        ciBannerWebview?.layoutIfNeeded()
    }
    
    // beid変更時
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didBeidChanged beid: String, recommendedItems: String, bannerType type: String) {
        print("didBeidChanged: beid: \(beid) recommendedItems: \(recommendedItems) type: \(type)")
    }
    
    // バナークリック時
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didBannerClicked: String, bannerType: String) {
        print("didBannerClicked: bannerType: \(bannerType)")
    }
}
