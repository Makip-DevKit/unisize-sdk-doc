import SwiftUI
import unisizeSDK

// MARK: - SwiftUI <-> UIKit ブリッジ
// SwiftUI から UIKit の UnisizeBannerWebview を使うための UIViewRepresentable ラッパー
struct UnisizeBannerWebviewRepresentable: UIViewRepresentable {

    // MARK: - バナー表示用パラメータ
    let bannerType: String // バナータイプ（例："text", "ex", "ci"）
    let bannerMode: String // 表示モード（"text,ex", "text", "ex"） ※ciは含めない
    let cid: String // クライアントID
    let itm: String // 商品識別ID
    let cuid: String // ECサイトのユーザー識別ID
    let lang: String // 表示言語（Default：ja）
    let enableWebViewLog: Bool // WebView内のconsole.logをXcodeに出力
    let enablePrintLog: Bool // SDKの内部ログ出力を有効化
    let sendErrorLog: Bool // エラーログ送信を有効化
    let customStyle: String // カスタムCSS（非推奨）

    // MARK: - イベントコールバック
    let onFinish: ((String, String) -> Void)? // 表示完了時
    let onFail: ((UnisizeError) -> Void)? // 表示失敗時
    let onResize: ((CGFloat, String) -> Void)? // バナーのリサイズ時
    let onUnsupported: ((String) -> Void)? // unisize対象外の場合
    let onBeidChanged: ((String, String, String) -> Void)? // beid変更時
    let onClicked: ((String) -> Void)? // バナークリック時
    let funcController: BannerFunctionController? // 外部からリロード・クローズ操作を可能にするコントローラ

    // MARK: - Coordinator（UIKitからSwiftUIへのイベントブリッジ）
    class Coordinator: NSObject, UnisizeBannerWebviewDelegate {
        let parent: UnisizeBannerWebviewRepresentable
        var bannerView: UnisizeBannerWebview?

        init(_ parent: UnisizeBannerWebviewRepresentable) {
            self.parent = parent
        }

        // MARK: - Delegate メソッド実装
        func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didFinish message: String, bannerType: String) {
            parent.onFinish?(message, bannerType)
        }

        func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didFail errorObj: UnisizeError) {
            parent.onFail?(errorObj)
        }

        func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didResized message: String, width: CGFloat, height: CGFloat, bannerType: String) {
            parent.onResize?(height, bannerType)
        }

        func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didUnsupported message: String) {
            parent.onUnsupported?(message)
        }

        func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didBeidChanged beid: String, recommendedItems: String, bannerType type: String) {
            parent.onBeidChanged?(beid, recommendedItems, type)
        }

        func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didBannerClicked: String, bannerType: String) {
            parent.onClicked?(bannerType)
        }
    }

    // MARK: - Coordinator 生成
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - UIView生成（初回のみ呼ばれる）
    func makeUIView(context: Context) -> UnisizeBannerWebview {
        let banner = UnisizeBannerWebview()
        if #available(iOS 15.0, *) {
            banner.translatesAutoresizingMaskIntoConstraints = false
        }
        context.coordinator.bannerView = banner

        // バナーを表示する親 UIViewController を取得
        let viewController = (UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostViewController())! // 最上位のViewControllerを取得

        // バナー初期設定
        banner.setupParam(
            parentView: viewController,
            bannerType: bannerType,
            bannerMode: bannerMode,
            cid: cid,
            itm: itm,
            cuid: cuid,
            lang: lang,
            enableWebViewLog: enableWebViewLog,
            enablePrintLog: enablePrintLog,
            sendErrorLog: sendErrorLog,
            delegate: context.coordinator,
            customStyle: customStyle
        )

        banner.show() // 表示開始

        // リロード・クローズ操作をコントローラ経由で外部に委譲
        funcController?.reloadAction = {
            banner.reload()
        }
        funcController?.closeAction = {
            banner.close()
        }

        return banner
    }

    // MARK: - View更新（バインディングやコントローラが変更された時に呼ばれる）
    func updateUIView(_ uiView: UnisizeBannerWebview, context: Context) {
        if #available(iOS 15.0, *) {
            if let superview = uiView.superview {
                NSLayoutConstraint.activate([
                    uiView.leadingAnchor .constraint(equalTo: superview.leadingAnchor),
                    uiView.trailingAnchor.constraint(equalTo: superview.trailingAnchor)
                ])
            }
        }
        
        // Viewが更新されても reload/close の参照を最新に保つ
        funcController?.reloadAction = {
            uiView.reload()
        }
        funcController?.closeAction = {
            uiView.close()
        }
    }
}

// MARK: - 最前面の ViewController を取得するためのユーティリティ拡張
extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = self.presentedViewController {
            return presented.topMostViewController() // モーダルなどがある場合は再帰的に最上位を取得
        }
        if let nav = self as? UINavigationController {
            return nav.visibleViewController?.topMostViewController() ?? nav
        }
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        return self
    }
}

// MARK: - SwiftUIからのリロード・クローズ操作を管理するコントローラ
class BannerFunctionController: ObservableObject {
    // SwiftUIから trigger 可能なリロード／クローズ用のクロージャ（UIView側で定義）
    fileprivate var reloadAction: (() -> Void)?
    fileprivate var closeAction: (() -> Void)?

    // SwiftUI側から実行可能なメソッド
    func reload() {
        reloadAction?()
    }

    func close() {
        closeAction?()
    }
}
