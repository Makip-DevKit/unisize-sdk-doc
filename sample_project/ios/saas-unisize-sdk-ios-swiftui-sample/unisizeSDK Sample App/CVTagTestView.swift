import SwiftUI
import UIKit
import unisizeSDK

// MARK: - SwiftUI <-> UIKit ブリッジ
// SwiftUI 上で Unisize の CV タグ（購入完了タグ）を表示するための UIViewRepresentable ラッパー
struct UnisizeCVTagView: UIViewRepresentable {

    // MARK: - 状態制御バインディング（親Viewから操作）
    @Binding var reloadTrigger: Bool // リロードのトリガー
    @Binding var shouldClose: Bool // 閉じるトリガー

    // MARK: - CVタグ表示に必要なパラメータ
    var cid: String = ""  // クライアントID
    var cuid: String = ""  // ECサイトのユーザー識別ID
    var purchaseid: String = ""  // 購入ID
    var itemnum: [String] = []  // 商品ごとの購入数
    var itemid: [String] = [] // 商品識別ID（商品ごと）
    var price: [String] = [] // 商品ごとの価格
    var size: [String] = [] // サイズ情報（商品ごと）
    var iteminfo: String = "" // ※通常は使用しない
    var iteminfojson: String = "" // ※通常は使用しない
    var regType: String = "" // ※通常は使用しない

    // MARK: - Coordinator（UIKitのDelegateとSwiftUIの橋渡し）
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - UIView の生成（初回のみ）
    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        // UnisizeCVTag に渡すため、各配列をURLエンコード風に結合（#のエスケープとして%23を使用）
        let itemnumString = itemnum.joined(separator: "%23")
        let itemidString = itemid.joined(separator: "%23")
        let priceString = price.joined(separator: "%23")
        let sizeString = size.joined(separator: "%23")

        // UnisizeCVTag インスタンスの生成
        let unisizeCvTag = UnisizeCVTag(
            cvTagRect: view, // 表示する親UIView
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
            enableWebViewLog: true, // WebView の console.log 出力有効化
            enablePrintLog: true, // SDK の print ログ出力
            sendErrorLog: true, // エラーログ送信
            delegate: context.coordinator // デリゲート指定
        )

        context.coordinator.cvTagInstance = unisizeCvTag // コーディネーターにインスタンス保持
        view.addSubview(unisizeCvTag) // UIViewに追加

        return view
    }

    // MARK: - SwiftUIの状態が変化した際の処理
    func updateUIView(_ uiView: UIView, context: Context) {
        if reloadTrigger {
            // reloadTrigger が true のとき、WebView をリロード
            context.coordinator.cvTagInstance?.reloadWebView()
        }

        if shouldClose {
            // shouldClose が true のとき、バナーを閉じる
            context.coordinator.cvTagInstance?.close()
        }
    }

    // MARK: - Coordinator（UnisizeCVTagDelegate 実装）
    class Coordinator: NSObject, UnisizeCVTagDelegate {
        var parent: UnisizeCVTagView
        var cvTagInstance: UnisizeCVTag?

        init(_ parent: UnisizeCVTagView) {
            self.parent = parent
        }

        // 表示完了イベント
        func unisizeCVTag(_ cvTag: UnisizeCVTag, didFinish message: String) {
            print("CVTag finished: \(message)")
        }

        // 表示失敗イベント
        func unisizeCVTag(_ cvTag: UnisizeCVTag, didFail errorObj: UnisizeError) {
            print("CVTag failed: \(errorObj.getJsonString())")
        }

        // WebView 読み込み完了イベント
        func unisizeCVTag(_ cvTag: UnisizeCVTag, didLoaded message: String) {
            print("CVTag loaded: \(message)")
        }
    }
}
