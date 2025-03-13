## unisizeSDK for iOS Swift 用サンプルコードについて
unisizeSDK for iOS Swift を使用して unisize の各機能を利用するための簡単なサンプルアプリケーションのプロジェクトです。
unisizeSDK を Swift で実装する場合の実装サンプルとして、また、機能テスト用としてご利用いただけます。  
  
※ SDKに付属している「導入手順」「SDKリファレンス」も合わせてご確認ください。  

## 使用しているSDK
* unisizeSDK for iOS Swift  

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
L28〜付近  
  
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
L27〜付近  

下記の部分に「クライアントID」、「クライアント会員ID」、「購入ID」、「購入数」、「アイテム識別ID」、「価格」、「サイズ」を設定して起動すると、画面表示時にCVタグが発火します。  
※ 実際に購入として集計されるため、起動する場合は、unisize が発行したテスト用クライアント識別ID（CID）を使用して実行して下さい。  
  
```swift
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
```
