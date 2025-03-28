#import "ViewController.h"
#import <UnisizeSDK/unisizeSDK.h>

@interface ViewController () <UnisizeBannerDelegate>

// IBOutlet変数：テキストフィールド（itm, cid, cuid, langの入力用）
@property (weak, nonatomic) IBOutlet UITextField *itmTextField;
@property (weak, nonatomic) IBOutlet UITextField *cidTextField;
@property (weak, nonatomic) IBOutlet UITextField *cuidTextField;
@property (weak, nonatomic) IBOutlet UITextField *langTextField;

// UnisizeBanner インスタンス
@property (weak, nonatomic) IBOutlet UnisizeBanner *unisizeBanner;

// WebViewの高さ制約
@property NSLayoutConstraint *textBannerWebviewHeightConstraint;
@property NSLayoutConstraint *exBannerWebviewHeightConstraint;
@property NSLayoutConstraint *ciBannerWebviewHeightConstraint;

// WebView バナーの参照
@property (weak, nonatomic) IBOutlet UnisizeBannerWebview *textBannerWebview;
@property (weak, nonatomic) IBOutlet UnisizeBannerWebview *exBannerWebview;
@property (weak, nonatomic) IBOutlet UnisizeBannerWebview *ciBannerWebview;

// バナー表示に使用するパラメータ
@property (nonatomic, strong) NSString *cid;
@property (nonatomic, strong) NSString *itm;
@property (nonatomic, strong) NSString *cuid;
@property (nonatomic, strong) NSString *lang;
@property (nonatomic, assign) BOOL enableWebViewLog;
@property (nonatomic, assign) BOOL enablePrintLog;
@property (nonatomic, assign) BOOL sendErrorLog;
@property (nonatomic, strong) NSString *customStyle;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"ViewController > viewDidLoad()");
    
    // 初期パラメータ設定
    self.cid = @"";
    self.itm = @"";
    self.cuid = @"";
    self.lang = @"";

    // Safariの開発者ツール用設定（WebKitデバッグ有効化）
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"WebKitDeveloperExtras"];

    // WebViewのAuto Layout対応
    NSArray<UnisizeBannerWebview *> *bannerWebviews = @[self.textBannerWebview, self.exBannerWebview, self.ciBannerWebview];
    for (UnisizeBannerWebview *banner in bannerWebviews) {
        banner.translatesAutoresizingMaskIntoConstraints = NO;
    }

    // 高さ制約の初期化（非表示状態）
    self.textBannerWebviewHeightConstraint = [self.textBannerWebview.heightAnchor constraintEqualToConstant:0];
    self.exBannerWebviewHeightConstraint = [self.exBannerWebview.heightAnchor constraintEqualToConstant:0];
    self.ciBannerWebviewHeightConstraint = [self.ciBannerWebview.heightAnchor constraintEqualToConstant:0];
    
    // 制約を有効化
    [NSLayoutConstraint activateConstraints:@[
        self.textBannerWebviewHeightConstraint,
        self.exBannerWebviewHeightConstraint,
        self.ciBannerWebviewHeightConstraint
    ]];

    // ログ設定
    self.enableWebViewLog = YES;
    self.enablePrintLog = YES;
    self.sendErrorLog = YES;
    self.customStyle = @"";

    // パラメータを元にバナーを初期化
    [self createBannerParam];
    
    // テキストバナーと CIバナーを表示
    [self.textBannerWebview show];
    [self.ciBannerWebview show];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    NSLog(@"ViewController > viewDidDisappear");

    // バナーのリソース解放と非表示化
    [self.textBannerWebview close];
    [self.exBannerWebview close];
    [self.ciBannerWebview close];

    self.textBannerWebview = nil;
    self.exBannerWebview = nil;
    self.ciBannerWebview = nil;
}

// バナーに必要なパラメータを構築
- (void)createBannerParam {
    NSLog(@"ViewController > createBannerParam()");
    
    // バナータイプごとに辞書配列で管理
    NSArray *bannerTypes = @[
        @{@"view": self.textBannerWebview ?: [NSNull null], @"type": @"text"},
        @{@"view": self.exBannerWebview ?: [NSNull null], @"type": @"ex"},
        @{@"view": self.ciBannerWebview ?: [NSNull null], @"type": @"ci"}
    ];
    
    // 使用可能なバナータイプを収集（"ci"以外）
    NSMutableArray *availableTypes = [NSMutableArray array];
    for (NSDictionary *entry in bannerTypes) {
        NSString *type = entry[@"type"];
        if (![entry[@"view"] isEqual:[NSNull null]] && ![type isEqualToString:@"ci"]) {
            [availableTypes addObject:type];
        }
    }
    
    // カンマ区切りでバナーモード指定
    NSString *bannerMode = [availableTypes componentsJoinedByString:@","];
    
    // 各バナーに対してパラメータを設定
    for (NSDictionary *entry in bannerTypes) {
        UnisizeBannerWebview *banner = [entry[@"view"] isEqual:[NSNull null]] ? nil : entry[@"view"];
        NSString *type = entry[@"type"];
        if (banner) {
            [self setupBannerParamWithBanner:banner bannerType:type bannerMode:bannerMode];
        }
    }
}

// バナー1つに対してパラメータを設定
- (void)setupBannerParamWithBanner:(UnisizeBannerWebview *)banner bannerType:(NSString *)type bannerMode:(NSString *)mode {
    NSLog(@"setupBannerParam: type: %@, mode: %@", type, mode);
    NSLog(@"bannerType: %@, bannerMode: %@, cid: %@, itm: %@, cuid: %@, lang: %@,", type, mode, self.cid, self.itm, self.cuid, self.lang);
    
    [banner setupParamWithParentView:self
                          bannerType:type
                          bannerMode:mode
                                 cid:self.cid
                                 itm:self.itm
                                cuid:self.cuid
                                lang:self.lang
                   enableWebViewLog:self.enableWebViewLog
                    enablePrintLog:self.enablePrintLog
                       sendErrorLog:self.sendErrorLog
                           delegate:self
                       customStyle:self.customStyle];
}

#pragma mark - IBAction

// CvTagテスト用画面遷移
- (IBAction)cvTagTestTapped:(UIButton *)sender {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"CvTagTestViewControllerID"];
    [self presentViewController:vc animated:YES completion:nil];
}

// バナーを再読み込み
- (IBAction)reloadButton:(id)sender {
    [self.textBannerWebview reload];
    [self.exBannerWebview reload];
    [self.ciBannerWebview reload];
}

// 入力フォーム送信時、バナーパラメータを更新して再表示
- (IBAction)formSend:(id)sender {
    self.cid = self.cidTextField.text ?: @"";
    self.itm = self.itmTextField.text ?: @"";
    self.cuid = self.cuidTextField.text ?: @"";
    self.lang = self.langTextField.text ?: @"";

    [self createBannerParam];
    [self.textBannerWebview show];
    [self.ciBannerWebview show];
}

#pragma mark - UnisizeBannerWebviewDelegate

// バナー読み込み完了時
- (void)unisizeBannerWebview:(UnisizeBannerWebview *)banner didFinish:(NSString *)message bannerType:(NSString *)type {
    NSLog(@"didFinish: %@", message);
    
    // テキストバナーが完了したら、exバナーを表示
    if ([type isEqualToString:@"text"]) {
        [self.exBannerWebview show];
    }
}

// バナー表示失敗時
- (void)unisizeBannerWebview:(UnisizeBannerWebview *)banner didFail:(UnisizeError *)errorObj {
    NSLog(@"didFail: %@", [errorObj getJsonString]);
    
    // 全バナーの高さを0にして非表示
    self.textBannerWebviewHeightConstraint.constant = 0;
    [self.textBannerWebview layoutIfNeeded];
    self.exBannerWebviewHeightConstraint.constant = 0;
    [self.exBannerWebview layoutIfNeeded];
    self.ciBannerWebviewHeightConstraint.constant = 0;
    [self.ciBannerWebview layoutIfNeeded];
}

// バナーサイズが変更されたときの処理（高さ調整）
- (void)unisizeBannerWebview:(UnisizeBannerWebview *)banner didResized:(NSString *)message width:(CGFloat)width height:(CGFloat)height bannerType:(NSString *)type {
    NSLog(@"didResized: width: %.2f height: %.2f type: %@", width, height, type);

    if ([type isEqualToString:@"text"]) {
        self.textBannerWebviewHeightConstraint.constant = height;
        [self.textBannerWebview layoutIfNeeded];
    } else if ([type isEqualToString:@"ex"]) {
        self.exBannerWebviewHeightConstraint.constant = height;
        [self.exBannerWebview layoutIfNeeded];
    } else if ([type isEqualToString:@"ci"]) {
        self.ciBannerWebviewHeightConstraint.constant = height;
        [self.ciBannerWebview layoutIfNeeded];
    }
}

// 対応していない場合（表示不可）→ 高さを0にして非表示
- (void)unisizeBannerWebview:(UnisizeBannerWebview *)banner didUnsupported:(NSString *)message {
    NSLog(@"didUnsupported: %@", message);
    
    if ([message isEqualToString:@"all"]) {
        self.textBannerWebviewHeightConstraint.constant = 0;
        [self.textBannerWebview layoutIfNeeded];
        self.exBannerWebviewHeightConstraint.constant = 0;
        [self.exBannerWebview layoutIfNeeded];
    }
    self.ciBannerWebviewHeightConstraint.constant = 0;
    [self.ciBannerWebview layoutIfNeeded];
}

// beidが変更されたときのログ出力
- (void)unisizeBannerWebview:(UnisizeBannerWebview *)banner didBeidChanged:(NSString *)beid recommendedItems:(NSString *)recommendedItems bannerType:(NSString *)type {
    NSLog(@"didBeidChanged: beid: %@ recommendedItems: %@ type: %@", beid, recommendedItems, type);
}

// バナーがクリックされたときのイベント
- (void)unisizeBannerWebview:(UnisizeBannerWebview *)banner didBannerClicked:(NSString *)bannerType {
    NSLog(@"didBannerClicked: bannerType: %@", bannerType);
}

@end
