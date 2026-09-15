## unisizeSDK for iOS Swift 用サンプルコードについて
unisizeSDK for iOS Swift を使用して unisize の各機能を利用するための簡単なサンプルアプリケーションのプロジェクトです。
unisizeSDK を Swift で実装する場合の実装サンプルとして、また、機能テスト用としてご利用いただけます。  

※ 本プロジェクトの動作には unisizeSDK v3.0以降が必要です。
※ SDKに付属している「導入手順」「SDKリファレンス」も合わせてご確認ください。  

## 使用しているSDK
* unisizeSDK for iOS Swift（v3.0.0以降）  
  ※ unisizeSDK の利用には unisize が発行したクライアント識別ID（CID）が必要です。

## プロジェクト内の主なファイル
* TopViewController.swift  
  起動時に表示されるトップページです。各検証画面への導線をまとめています。<br><br>
* ViewController.swift  
  UnisizeBannerWebview Class の実装を確認いただけます。<br><br>
* CVTagTestViewController.swift  
  UnisizeCVTag Class の実装を確認いただけます。 <br><br>   
* AunnCoordinateTestViewController.swift  
  AunnCoordinate Class（aunn コーディネート単独）の実装を確認いただけます。<br><br>
* AunnCoordinateWithUnisizeTestViewController.swift  
  AunnCoordinate と UnisizeBannerWebview を同一画面に同居させた場合の実装を確認いただけます。<br><br>
* AunnCoordinateGridViews.swift  
  aunn コーデ一覧をホストアプリ側でネイティブ描画する際の共通部品（2カラムのグリッド表示）です。<br><br>
* CoordinateDetailDialog.swift  
  aunn の API から取得したコーデ 1 件の内容を確認するための検証用ダイアログです。<br><br>
* SampleImageLoader.swift  
  サンプル用の簡易画像ローダーです（ライブラリ非依存）。実アプリでは SDWebImage / Kingfisher 等の利用を想定しています。<br><br>
* Main.storyboard  
  サンプルで使用している ViewController のストーリーボードが含まれています。 <br><br> 

## 画面構成
起動するとトップページ（TopViewController）が表示されます。  
トップページの各ボタンから、下記の検証画面へ遷移します。  

* unisize Banner Test  
  unisize バナーの表示テスト画面です（ViewController）。CVタグの発火テスト画面へもこの画面から遷移します。<br><br>
* aunn コーディネート単独 test  
  aunn パーソナライズ SDK 単独の検証画面です。コーデ一覧の取得（ネイティブ描画）、体型登録、コーデ詳細／スタッフ詳細の View 計測を確認できます。<br><br>
* aunn コーディネート + unisize Test  
  aunn のコーデ一覧と unisize バナーを同一画面に同居させた検証画面です。商品詳細ページを想定し、体型登録の反映が双方向に連携することを確認できます。<br><br>

## プロジェクトの設定
USBでiPhone実機を繋いで起動する場合は、事前に
プロジェクトの設定 > Signing & Capabilities の Siging > Team 
を設定して下さい。
（シミュレーター上での起動の場合は不要です。）

## unisizeバナーの表示テスト
unisizeSDK Sample App > unisizeSDK Sample App > ViewController.swift  
L36〜  
  
下記の部分に「クライアントID」、「商品識別ID」を設定して起動して下さい。  
unisizeバナーが表示されます。  
  
```swift
    var cid: String = "" // クライアントID
    var itm: String = "" // 商品識別ID
    var cuid: String = "" // ECサイトのユーザー識別ID
    var lang: String = "" // 表示言語（Default：ja）
```
  
## CVタグの発火テスト
unisizeSDK Sample App > unisizeSDK Sample App > CVTagTestViewController.swift
L33〜  

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

## aunn コーディネートの表示テスト
トップページの「aunn コーディネート単独 test」「aunn コーディネート + unisize Test」から遷移します。  

cid / cuid / itemId は画面上の入力欄から変更できるため、テストケースごとにビルドし直す必要はありません。  
既定値を変更する場合は、各 ViewController の下記の部分を書き換えて下さい。  

```swift
    private let defaultCid = "" // クライアントID
    private let defaultItemId = "" // 商品識別ID
```

- cuid は未入力を既定としており、入力されたときだけ送信します（cuid を送ると体型推定が働き、レコメンドの種別が変わるためです）。
- 「コーデ取得（load）」でコーデ一覧を取得します。コーデのセルを長押しすると、API から取得した全項目をダイアログとコンソールで確認できます。
- 「aunn コーディネート + unisize Test」では、cid / itemId は aunn・unisize 双方で有効な値を設定して下さい。
