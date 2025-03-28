## unisizeSDK for iOS Swift 用サンプルコードについて
unisizeSDK for iOS Swift を使用して unisize の各機能を利用するための簡単なサンプルアプリケーションのプロジェクトです。
unisizeSDK を Swift で実装する場合の実装サンプルとして、また、機能テスト用としてご利用いただけます。  

※ 本プロジェクトの動作には unisizeSDK v2.0以降が必要です。
※ SDKに付属している「導入手順」「SDKリファレンス」も合わせてご確認ください。  

## 使用しているSDK
* unisizeSDK for iOS Swift（v2.0以降）  
  ※ unisizeSDK の利用には unisize が発行したクライアント識別ID（CID）が必要です。

## プロジェクト内の主なファイル
* ViewController.swift  
  UnisizeBanner Class の実装を確認いただけます。<br><br>
* CVTagTestViewController.swift  
  UnisizeCVTag Class の実装を確認いただけます。 <br><br>   
* Main.storyboard  
  サンプルで使用している ViewController のストーリーボードが含まれています。 <br><br> 

## プロジェクトの設定
USBでiPhone実機を繋いで起動する場合は、事前に
プロジェクトの設定 > Signing & Capabilities の Siging > Team 
を設定して下さい。
（シミュレーター上での起動の場合は不要です。）

## unisizeバナーの表示テスト
unisizeSDK Sample App > unisizeSDK Sample App > ViewController.swift  
L20〜  
  
下記の部分に「クライアントID」、「アイテム識別ID」を設定して起動して下さい。  
unisizeバナーが表示されます。  
  
```swift
    var cid: String = "" // クライアントID
    var itm: String = "" // アイテム識別ID
    var cuid: String = "" // クライアント会員ID
    var lang: String = "" // 表示言語(オプション)
```
  
## CVタグの発火テスト
unisizeSDK Sample App > unisizeSDK Sample App > CVTagTestViewController.swift
L20〜  

下記の部分に「クライアントID」、「ECサイトのユーザー識別ID」、「購入ID」、「商品ごとの購入数」、「商品識別ID（商品ごと）」、「商品ごとの価格」、「サイズ情報（商品ごと）」を設定して起動すると、画面表示時にCVタグが発火します。  
※ 実際に購入として集計されるため、起動する場合は、unisize が発行したテスト用クライアント識別ID（CID）を使用して実行して下さい。  
  
```swift
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
```
  
- 送信すると実際に購入として集計されるため、起動する場合は、unisize が発行したテスト用クライアント識別ID（CID）を使用して実行して下さい。  
- iPhone 端末と Mac を繋いで Safari を使った開発モードを使うと、開発ツールのネットワークタブでトラッキングが送信されているかの確認が可能です。「tracking」という項目を選択すると送信された情報などを確認できます。 
