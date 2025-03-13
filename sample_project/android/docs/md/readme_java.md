## unisizeSDK for Android Java 用サンプルコードについて
unisizeSDK for Android Java を使用して unisize の各機能を利用するための簡単なサンプルアプリケーションのプロジェクトです。
unisizeSDK を Java で実装する場合の実装サンプルとして、また、機能テスト用としてご利用いただけます。  
  
※ SDKに付属している「導入手順」「SDKリファレンス」も合わせてご確認ください。  

## 使用しているSDK
* unisizeSDK for Android Kotlin  

※ unisizeSDK の利用には unisize が発行したクライアント識別ID（CID）が必要です。

## 動作環境
* Android 11（API レベル 30）、またはそれ以降

## プロジェクト内の主なファイル
* MainActivity.java  
  UnisizeBanner Class の実装を確認いただけます。<br><br>
* CVTagTestActivity.java  
  UnisizeCVTag Class の実装を確認いただけます。 <br><br>   
* /layout  
  サンプルで使用しているアクティビティのレイアウトファイルが含まれています。 <br><br> 

## unisizeバナーの表示テスト

MainActivity.java  
L27〜28  
  
下記の部分に「クライアントID」、「アイテム識別ID」を設定して起動して下さい。  
unisizeバナーが表示されます。  

```java
    private String cid = ""; // クライアントID
    private String itm = ""; // アイテム識別ID
    private String cuid = ""; // クライアント会員ID
    private String lang = ""; // 表示言語(オプション)
```

## CVタグの発火テスト
unisizeSDK Sample App > unisizeSDK Sample App > CVTagTestViewController.java  
L27〜36

下記の部分に「クライアントID」、「クライアント会員ID」、「購入ID」、「購入数」、「アイテム識別ID」、「価格」、「サイズ」を設定して起動すると、画面表示時にCVタグが発火します。  
実装方法の確認用としてご利用ください。  
※ 実際に購入として集計されるため、起動する場合は、unisize が発行したテスト用クライアント識別ID（CID）を使用して実行して下さい。  
  
```java
  String cid = "";  // クライアントID
  String cuid = ""; // ECサイトの会員ID
  String purchaseid = ""; // 購入時に発行された注文ID
  List<String> itemnum = Arrays.asList("", ""); // 購入数（アイテム毎）
  List<String> itemid = Arrays.asList("", ""); // 購入アイテムのアイテムID
  List<String> price = Arrays.asList("", ""); // 購入アイテムの金額（アイテム毎）
  List<String> size = Arrays.asList("", ""); // 購入したアイテムのサイズ（アイテム毎）
  String iteminfo = "";
  String regType = "";
```
