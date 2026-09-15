## unisizeSDK for Android Kotlin 用サンプルコードについて
unisizeSDK for Android Kotlin を使用して unisize の各機能を利用するための簡単なサンプルアプリケーションのプロジェクトです。
unisizeSDK を Kotlin で実装する場合の実装サンプルとして、また、機能テスト用としてご利用いただけます。  
  
※ SDKに付属している「導入手順」「SDKリファレンス」も合わせてご確認ください。  

## 使用しているSDK
* unisizeSDK for Android Kotlin  

※ unisizeSDK の利用には unisize が発行したクライアント識別ID（CID）が必要です。

## 動作環境
* Android 11（API レベル 30）、またはそれ以降

## プロジェクト内の主なファイル
* MainActivity.kt  
  UnisizeBanner Class の実装を確認いただけます。<br><br>
* CVTagTestActivity.kt  
  UnisizeCVTag Class の実装を確認いただけます。 <br><br>   
* /layout  
  サンプルで使用しているアクティビティのレイアウトファイルが含まれています。 <br><br> 

## unisizeバナーの表示テスト

MainActivity.kt  
L27〜28  
  
下記の部分に「クライアントID」、「アイテム識別ID」を設定して起動して下さい。  
unisizeバナーが表示されます。  

```kotlin
    private var cid: String = ""
    private var itm: String = ""
    private var cuid: String = ""
    private var lang: String = ""
```

## CVタグの発火テスト
unisizeSDK Sample App > unisizeSDK Sample App > CVTagTestViewController.swift  
L27〜36  

下記の部分に「クライアントID」、「クライアント会員ID」、「購入ID」、「購入数」、「アイテム識別ID」、「価格」、「サイズ」を設定して起動すると、画面表示時にCVタグが発火します。  
実装方法の確認用としてご利用ください。  
※ 実際に購入として集計されるため、起動する場合は、unisize が発行したテスト用クライアント識別ID（CID）を使用して実行して下さい。  
  
```kotlin
    val cid: String = ""  // クライアントID
    val cuid: String = "" // ECサイトの会員ID
    val purchaseid: String = "" // 購入時に発行された注文ID
    val itemnum: List<String> = listOf("") // 購入数（アイテム毎）
    val itemid: List<String> = listOf("") // 購入アイテムのアイテムID
    val price: List<String> = listOf("") // 購入アイテムの金額（アイテム毎）
    val size: List<String> = listOf("") // 購入したアイテムのサイズ（アイテム毎）
    val iteminfo: String = ""
    val regType: String = ""
```
