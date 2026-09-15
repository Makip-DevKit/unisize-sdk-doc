import UIKit
import WebKit
import unisizeSDK

// MARK: - ViewController（unisize バナーの実装サンプル）
/*
 * UnisizeBannerWebview を使って unisize バナーを表示する検証用画面です（Main.storyboard 上に配置）。
 *
 * 実装の流れは次の 3 ステップです。
 *  1. Storyboard に置いた UnisizeBannerWebview に高さ制約（初期値 0）を設定する
 *  2. setupParam() で cid / itm などのパラメータと delegate を設定する
 *  3. show() で読み込みを開始し、delegate の didResized で高さ制約を実際のバナー高さへ更新する
 *
 * バナーは 3 種類あり、この画面ではそれぞれを個別の UnisizeBannerWebview として配置しています。
 *  - text：サイズ表記の近くに置くテキスト型バナー
 *  - ex  ：詳細情報を表示する拡張バナー（TEXT バナーの表示完了後に show() します）
 *  - ci  ：カート導線などに置くバナー（bannerMode には含めません）
 *
 * cid / itm / cuid / lang は画面上のフォームからも変更できます。
 * 画面下部のボタンから CV タグの検証画面（CvTagTestViewController）へ遷移します。
 */
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
    // ※ cid / itm は必須です。ここに値を設定するか、画面上のフォームから入力して下さい。
    var cid: String = "" // クライアントID
    var itm: String = "" // 商品識別ID
    var cuid: String = "" // ECサイトのユーザー識別ID
    var lang: String = "" // 表示言語（Default：ja）
    var enableWebViewLog: Bool = true // WebView内のconsole.logをXcodeに出力
    var enablePrintLog: Bool = true // SDKの内部ログ出力を有効化
    var sendErrorLog: Bool = true // エラーログ送信を有効化
    var customStyle: String = "" // カスタムCSS（非推奨）
    
    // MARK: - 高さ制約（各バナー用）
    // バナーの高さは表示内容によって変わるため、delegate の didResized で更新します。
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
        print("ViewController > viewDidDisappear")

        // 他の画面を重ねただけのときに破棄しないよう、実際に画面を離れるとき（pop / dismiss）だけ解放します。
        // CV タグ画面はシート表示のためここへは来ませんが、全画面表示に変更しても壊れないようにするためです。
        guard isMovingFromParent || isBeingDismissed else {
            return
        }

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
        
        // bannerMode は「この画面で表示するバナーの種類」をSDKへ伝えるパラメータです。
        // CIバナーは対象外のため bannerMode から除外します。
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
    
    /// バナーの表示完了時に呼ばれます。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didFinish message: String, bannerType: String) {
        print("didFinish: message: \(message)")
        
        // EXバナーはTEXTバナー完了後に.show()します。
        if (bannerType == "text") {
            exBannerWebview?.show()
        }
    }
    
    /// バナーの表示失敗時に呼ばれます。表示できないため、全バナーの高さを 0 に畳みます。
    /// ※ 引数は bannerType までが SDK の宣言です。UnisizeBannerWebviewDelegate は全メソッドが
    ///   @objc optional のため、シグネチャを間違えるとコンパイルは通ったまま呼ばれなくなります。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didFail errorObj: UnisizeError, bannerType: String) {
        print("didFail: bannerType: \(bannerType) \(errorObj.getJsonString())")
        
        // 高さを0にして非表示にする
        textBannerWebviewHeightConstraint?.constant = 0
        textBannerWebview?.layoutIfNeeded()
        exBannerWebviewHeightConstraint?.constant = 0
        exBannerWebview?.layoutIfNeeded()
        ciBannerWebviewHeightConstraint?.constant = 0
        ciBannerWebview?.layoutIfNeeded()
    }
    
    /// バナーの実寸が確定・変化したときに呼ばれます。
    /// 受け取った height を高さ制約へ反映しないとバナーが表示されないため、必ず実装して下さい。
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
    
    /// unisize の対象外商品だった場合に呼ばれます（message == "all" は全バナーが対象外）。
    /// 対象外のバナーは高さを 0 にして非表示にします。
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
    
    /// beid（unisize が発行するユーザー識別子）が変わったときに呼ばれます。
    /// 体型登録・サイズレコメンドの結果を他機能へ連携したい場合に利用します。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didBeidChanged beid: String, recommendedItems: String, bannerType type: String) {
        print("didBeidChanged: beid: \(beid) recommendedItems: \(recommendedItems) type: \(type)")
    }
    
    /// バナーがクリックされたときに呼ばれます。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didBannerClicked: String, bannerType: String) {
        print("didBannerClicked: bannerType: \(bannerType)")
    }
}
