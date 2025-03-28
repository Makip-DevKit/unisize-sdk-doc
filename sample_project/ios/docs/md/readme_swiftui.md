## unisizeSDK for iOS SwiftUI 用サンプルコードについて
unisizeSDK for iOS を SwiftUI のプロジェクトで unisize の各機能を利用するための簡単なサンプルアプリケーションのプロジェクトです。
unisizeSDK を SwiftUI で実装する場合の実装サンプルとして、また、機能テスト用としてご利用いただけます。  
  
※ SDKに付属している「導入手順」「SDKリファレンス」も合わせてご確認ください。  

## 使用しているSDK
* unisizeSDK for iOS Swift (v2.0以降）  
  ※ unisizeSDK の利用には unisize が発行したクライアント識別ID（CID）が必要です。  
  
## プロジェクト内の主なファイル
* ContentView.swift／UnisizeBannerWebviewRepresentable.swift  
  UnisizeBanner Class の実装を確認いただけます。<br><br>
* CVTagTestView.swift  
  UnisizeCVTag Class の実装を確認いただけます。<br><br>   

## プロジェクトの設定
USBでiPhone実機を繋いで起動する場合は、事前に  
プロジェクトの設定 > Signing & Capabilities の Siging > Team  
を設定して下さい。  
  
## unisizeバナーの表示テスト
unisizeSDK Sample App > unisizeSDK Sample App > ContentView.swift  
L6〜  
  
下記の部分に「クライアントID」、「アイテム識別ID」を設定して起動して下さい。  
unisizeバナーが表示されます。  
  
```swift
    @State private var cid: String = "" // クライアントID
    @State private var itm: String = "" // 商品識別ID
    @State private var cuid: String = "" // ECサイトのユーザー識別ID
    @State private var lang: String = "" // 表示言語（Default ："ja"）
```
  
## CVタグの発火テスト
unisizeSDK Sample App > unisizeSDK Sample App > ContentView.swift  
L196

下記の部分に「クライアントID」、「ECサイトのユーザー識別ID」、「購入ID」、「商品ごとの購入数」、「商品識別ID」、「商品ごとの価格」、「サイズ情報（商品ごと）」を設定して起動すると、画面表示時にCVタグが発火します。   
  
```swift
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
```
  
- 送信すると実際に購入として集計されるため、起動する場合は、unisize が発行したテスト用クライアント識別ID（CID）を使用して実行して下さい。  
- iPhone 端末と Mac を繋いで Safari を使った開発モードを使うと、開発ツールのネットワークタブでトラッキングが送信されているかの確認が可能です。「tracking」という項目を選択すると送信された情報などを確認できます。 
