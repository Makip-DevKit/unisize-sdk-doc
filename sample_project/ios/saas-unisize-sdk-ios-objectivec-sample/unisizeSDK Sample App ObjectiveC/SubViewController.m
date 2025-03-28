#import "SubViewController.h"
#import <UnisizeSDK/unisizeSDK.h>

@interface SubViewController () <UnisizeCVTagDelegate>

// CVタグを表示するUIView
@property (weak, nonatomic) IBOutlet UIView *cvTagRect;

// リロードボタン（CVタグWebViewの再読み込み用）
@property (weak, nonatomic) IBOutlet UIButton *reloadbutton;

// UnisizeCVTag インスタンス
@property (strong, nonatomic) UnisizeCVTag *unisizeCvTag;

@end

@implementation SubViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // --- UnisizeCVTag 初期化用パラメータ定義 ---

    NSString *cid = @"";         // クライアントID（Unisizeから発行されるユニークなID）
    NSString *cuid = @"";        // 会員ID（ユーザー識別用のID）
    NSString *purchaseid = @"";  // 購入ID（1つの注文を識別するID）

    // 商品ごとの情報（通常は商品数に応じて複数）
    NSArray<NSString *> *itemnum = @[]; // 購入数（例: @[@"1", @"2"]）
    NSArray<NSString *> *itemid = @[];  // 商品ID（例: @[@"a12345", @"bs22345", @"ld653_4"]）
    NSArray<NSString *> *price = @[];   // 商品価格（例: @[@"5000", @"7800", @"1980"]）
    NSArray<NSString *> *size = @[];    // 商品サイズ: @[@"S", @"M", @"L"]）

    // iteminfo: 全データをまとめて送る場合に使用（個別データを送らない場合）
    NSString *iteminfo = @"";

    // regType: iteminfoの形式を示す文字列（例: @"json"）
    NSString *regType = @"test";

    // --- データのフォーマット変換（Unisizeが受け取れる形式） ---
    // 配列 → "#" 区切りの文字列に変換
    NSString *itemnumString = [itemnum componentsJoinedByString:@"%23"];
    NSString *itemidString = [itemid componentsJoinedByString:@"%23"];
    NSString *priceString = [price componentsJoinedByString:@"%23"];
    NSString *sizeString = [size componentsJoinedByString:@"%23"];
    
    // --- UnisizeCVTag のインスタンス生成 ---
    self.unisizeCvTag =[[UnisizeCVTag alloc]
                                 initWithCvTagRect:_cvTagRect // 表示先の UIView
                                 cid:cid
                                 cuid:cuid
                                 purchaseid:purchaseid
                                 itemnum:itemnumString
                                 itemid:itemidString
                                 price:priceString
                                 size:sizeString
                                 iteminfo:iteminfo
                                 iteminfojson:iteminfo // JSON形式の場合にも使う
                                 regType:regType
                                 enableWebViewLog:YES   // WebViewデバッグログ出力
                                 enablePrintLog:YES     // コンソールログ出力
                                 sendErrorLog:YES       // エラーログを送信
                                 delegate:self];        // デリゲート設定（イベント通知受け取り）
}

/*
    リロードボタンがタップされたときに、CVタグの WebView を再読み込みする
*/
- (IBAction)reloadbutton:(id)sender {
    [self.unisizeCvTag reloadWebView];
}

/*
    閉じるボタンのアクション（モーダルを閉じる）
*/
- (IBAction)closeButtonTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^{
        // モーダルが閉じられた後に UnisizeCVTag をクローズ
        [self.unisizeCvTag close];
        self.unisizeCvTag = nil; // メモリ解放（明示的にnil代入）
    }];
}

/*
    UnisizeCVTagDelegate の各種コールバック
*/

// 正常に表示が完了したときに呼ばれる
- (void)unisizeCVTag:(UnisizeCVTag *)cvTag didFinish:(NSString *)message {
    NSLog(@"%@", message);
}

// 表示に失敗したときに呼ばれる（エラー内容をログ出力）
- (void)unisizeCVTag:(UnisizeCVTag *)cvTag didFail:(UnisizeError *)errorObj {
    NSLog(@"%@", [errorObj getJsonString]);
}

// WebViewの読み込みが完了したタイミングで呼ばれる
- (void)unisizeCVTag:(UnisizeCVTag *)cvTag didLoaded:(NSString *)message {
    NSLog(@"%@", message);
}

@end
