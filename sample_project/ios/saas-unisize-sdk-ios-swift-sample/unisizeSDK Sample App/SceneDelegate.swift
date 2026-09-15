import UIKit

// MARK: - SceneDelegate（画面（Scene）単位のライフサイクル）
/*
 * Xcode のテンプレートそのままの実装です。
 * 画面表示は Main.storyboard の UINavigationController（rootViewController は TopViewController）から始まります。
 *
 * unisizeSDK 側の破棄処理（close() など）は各 ViewController の viewDidDisappear で行っているため、
 * ここに unisize 用のコードを追加する必要はありません。
 */
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// Scene がアプリに接続されたときに呼ばれます（Storyboard 利用時は window が自動生成されます）。
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let _ = (scene as? UIWindowScene) else { return }
    }

    /// Scene が破棄されるときに呼ばれます（再生成できるリソースの解放用）。
    func sceneDidDisconnect(_ scene: UIScene) {
    }

    /// Scene がアクティブになったときに呼ばれます（中断していた処理の再開用）。
    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    /// Scene が非アクティブになるときに呼ばれます（着信などの一時的な中断を含みます）。
    func sceneWillResignActive(_ scene: UIScene) {
    }

    /// Scene がバックグラウンドからフォアグラウンドへ戻るときに呼ばれます。
    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    /// Scene がバックグラウンドへ移るときに呼ばれます（状態の保存用）。
    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
