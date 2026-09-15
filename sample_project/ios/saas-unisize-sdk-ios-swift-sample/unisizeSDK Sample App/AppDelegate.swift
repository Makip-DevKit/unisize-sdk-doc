import UIKit

// MARK: - AppDelegate（アプリ全体のライフサイクル）
/*
 * Xcode のテンプレートそのままの実装です。
 * unisizeSDK はアプリ起動時の初期化（SDK 全体の初期化処理）を必要としないため、
 * ここに unisize 用のコードを追加する必要はありません。
 * SDK の設定は各画面（ViewController）で setupParam() 等により行います。
 */
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// アプリ起動完了時に呼ばれます。
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    /// 新しい Scene を作成するときの構成を返します。
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// ユーザーが Scene を破棄したときに呼ばれます（破棄された Scene 固有のリソース解放用）。
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
