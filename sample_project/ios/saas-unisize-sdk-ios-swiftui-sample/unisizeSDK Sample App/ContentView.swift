import SwiftUI
import unisizeSDK // Unisize SDK：バナー表示やCVタグ処理などを提供

struct ContentView: View {

    // MARK: - unisizeバナー用パラメータ
    @State private var cid: String = "" // クライアントID
    @State private var itm: String = "" // 商品識別ID
    @State private var cuid: String = "" // ECサイトのユーザー識別ID
    @State private var lang: String = "" // 表示言語（Default ："ja"）

    // MARK: - バナーの高さ管理
    @State private var textBannerHeight: CGFloat = 0 // テキストバナーの高さ
    @State private var exBannerHeight: CGFloat = 0 // 拡張バナーの高さ
    @State private var ciBannerHeight: CGFloat = 0 // カートインバナーの高さ

    // MARK: - バナーリロード用のコントローラ（各バナーに1つ）
    @StateObject private var textBannerController = BannerFunctionController()
    @StateObject private var exBannerController = BannerFunctionController()
    @StateObject private var ciBannerController = BannerFunctionController()

    // MARK: - Viewの再描画トリガー（id変更でViewを更新）
    @State private var textBannerID = UUID()
    @State private var exBannerID = UUID()
    @State private var ciBannerID = UUID()

    // MARK: - 表示制御フラグ
    @State private var showExBanner = false // TEXTバナー完了後にEXバナーを表示
    @State private var showCvTagView = false // CVタグテスト画面をモーダル表示

    // MARK: - 本体View

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // MARK: - 入力フォーム
                Group {
                    HStack {
                        Text("itm").frame(width: 50, alignment: .leading)
                        TextField("itm", text: $itm).textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("cid").frame(width: 50, alignment: .leading)
                        TextField("cid", text: $cid).textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("cuid").frame(width: 50, alignment: .leading)
                        TextField("cuid", text: $cuid).textFieldStyle(.roundedBorder)
                    }
                    HStack {
                        Text("lang").frame(width: 50, alignment: .leading)
                        TextField("lang", text: $lang).textFieldStyle(.roundedBorder)
                    }

                    // バナーのUUIDを更新してViewを強制的にリロード
                    Button("更新") {
                        textBannerID = UUID()
                        exBannerID = UUID()
                        ciBannerID = UUID()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                // MARK: - TEXTバナー表示
                Text("Banner").font(.headline)

                UnisizeBannerWebviewRepresentable(
                    bannerType: "text", // バナータイプ（例："text", "ex", "ci"）
                    bannerMode: "text,ex", // 表示モード（"text,ex", "text", "ex"） ※ciは含めない
                    cid: cid, // クライアントID
                    itm: itm, // 商品識別ID
                    cuid: cuid, // ECサイトのユーザー識別ID
                    lang: lang, // 表示言語（Default：ja）
                    enableWebViewLog: true, // WebView内のconsole.logをXcodeに出力
                    enablePrintLog: true, // SDKの内部ログ出力を有効化
                    sendErrorLog: true, // エラーログ送信を有効化
                    customStyle: "", // カスタムCSS（非推奨）
                    // 表示完了時：TEXTバナー完了後に、EXバナー表示トリガー
                    onFinish: { message, bannerType in
                        if bannerType == "text" {
                            showExBanner = true
                        }
                    },
                    onFail: { _ in textBannerHeight = 0 }, // 表示失敗時：高さ0に設定して非表示化
                    onResize: { height, _ in textBannerHeight = height }, // バナーのリサイズ時：高さを更新
                    onUnsupported: { _ in textBannerHeight = 0 }, // unisize対象外の場合：高さ0に設定
                    onBeidChanged: {_,_,_ in }, // beid変更時
                    onClicked: {_ in }, // バナークリック時
                    funcController: textBannerController
                )
                .id(textBannerID) // UUID変更で再描画
                .frame(height: textBannerHeight) // 動的に高さを設定

                // MARK: - EXバナー表示
                if showExBanner {
                    UnisizeBannerWebviewRepresentable(
                        bannerType: "ex",
                        bannerMode: "text,ex",
                        cid: cid,
                        itm: itm,
                        cuid: cuid,
                        lang: lang,
                        enableWebViewLog: true,
                        enablePrintLog: true,
                        sendErrorLog: true,
                        customStyle: "",
                        onFinish: { _, _ in },
                        onFail: { _ in exBannerHeight = 0 },
                        onResize: { height, _ in exBannerHeight = height },
                        onUnsupported: { _ in exBannerHeight = 0 },
                        onBeidChanged: {_,_,_ in },
                        onClicked: {_ in },
                        funcController: exBannerController
                    )
                    .id(exBannerID)
                    .frame(height: exBannerHeight)
                }

                // MARK: - CIバナー（単独バナー）
                UnisizeBannerWebviewRepresentable(
                    bannerType: "ci",
                    bannerMode: "ci",
                    cid: cid,
                    itm: itm,
                    cuid: cuid,
                    lang: lang,
                    enableWebViewLog: true,
                    enablePrintLog: true,
                    sendErrorLog: true,
                    customStyle: "",
                    onFinish: { _, _ in },
                    onFail: { _ in ciBannerHeight = 0 },
                    onResize: { height, _ in ciBannerHeight = height },
                    onUnsupported: { _ in ciBannerHeight = 0 },
                    onBeidChanged: {_,_,_ in },
                    onClicked: {_ in },
                    funcController: ciBannerController
                )
                .id(ciBannerID)
                .frame(height: max(ciBannerHeight, 1)) // 高さ0だと表示されないので1以上に

                // MARK: - 下部ボタン（リロード & CVタグ表示）

                HStack {
                    // 全バナーを手動でリロード
                    Button("Reload") {
                        textBannerController.reload()
                        exBannerController.reload()
                        ciBannerController.reload()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    // 購入完了画面（CVタグ）モーダル表示
                    Button("購入完了画面") {
                        showCvTagView = true
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .sheet(isPresented: $showCvTagView) {
                        CvTagTestView() // 別ViewでCVタグの動作確認
                    }
                }
            }
            .padding()
        }
        // MARK: - 画面離脱時の処理（メモリリーク・リソース開放防止）
        .onDisappear {
            textBannerController.close()
            exBannerController.close()
            ciBannerController.close()
        }
    }
}

// MARK: - CVタグ テスト用の SwiftUI 画面
struct CvTagTestView: View {
    @Environment(\.presentationMode) var presentationMode // モーダルを閉じるための環境変数
    @State private var reloadTrigger = false // リロードフラグ
    @State private var shouldClose = false // 閉じるフラグ（trueで閉じる）

    // MARK: - デモ用のパラメータ（固定値）
    let cid: String = ""
    let cuid: String = ""
    let purchaseid: String = ""
    let itemnum: [String] = []
    let itemid: [String] = []
    let price: [String] = []
    let size: [String] = []
    let iteminfo: String = ""
    let regType: String = ""

    var body: some View {
        VStack {
            // MARK: - UnisizeCVTag 表示部分
            UnisizeCVTagView(
                reloadTrigger: $reloadTrigger,
                shouldClose: $shouldClose,
                cid: cid,
                cuid: cuid,
                purchaseid: purchaseid,
                itemnum: itemnum,
                itemid: itemid,
                price: price,
                size: size,
                iteminfo: iteminfo,
                iteminfojson: "",
                regType: regType
            )
            .frame(height: 300)
            .background(Color.gray.opacity(0.2))

            // MARK: - WebViewリロードボタン
            Button(action: {
                reloadTrigger.toggle() // リロードトリガーを送信
            }) {
                Text("Reload WebView")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)

            // MARK: - 閉じるボタン
            Button(action: {
                shouldClose = true // WebViewを閉じるトリガーを送信
                // 少し遅延させてモーダル自体も閉じる
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Close")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding(.horizontal, 20)
    }
}
