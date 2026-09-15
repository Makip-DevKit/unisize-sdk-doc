import UIKit

// MARK: - TopViewController（サンプルアプリのトップページ）
/*
 * サンプルアプリ起動時に表示されるトップページです。
 * 各検証画面への導線をここにまとめています。
 *
 * - unisize Banner Test：UnisizeBanner / UnisizeCVTag の実装サンプル（ViewController）
 * - aunn コーディネート単独 test：aunn パーソナライズ SDK 単独の検証画面
 * - aunn コーディネート + unisize Test：aunn と unisize バナーを同一画面に同居させた検証画面
 *
 * aunn の検証画面は「すべて見る」やコーデ詳細で push 遷移するため、
 * トップページは UINavigationController の rootViewController として配置しています。
 */
class TopViewController: UIViewController {

    // MARK: - IBOutlet（Storyboard接続）
    @IBOutlet weak var unisizeBannerTestButton: UIButton!
    @IBOutlet weak var aunnCoordinateTestButton: UIButton!
    @IBOutlet weak var aunnCoordinateWithUnisizeTestButton: UIButton!

    // MARK: - ライフサイクル
    override func viewDidLoad() {
        super.viewDidLoad()
        print("TopViewController > viewDidLoad()")

        title = "unisizeSDK Sample App"
    }

    // MARK: - UIアクション（ボタン）

    /// unisize バナー検証画面（ViewController）へ遷移
    @IBAction func unisizeBannerTestTapped(_ sender: Any) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "ViewControllerID")
        navigationController?.pushViewController(viewController, animated: true)
    }

    /// aunn コーディネート単独の検証画面へ遷移
    @IBAction func aunnCoordinateTestTapped(_ sender: Any) {
        navigationController?.pushViewController(AunnCoordinateTestViewController(), animated: true)
    }

    /// aunn コーディネート + unisize バナー同居の検証画面へ遷移
    @IBAction func aunnCoordinateWithUnisizeTestTapped(_ sender: Any) {
        navigationController?.pushViewController(AunnCoordinateWithUnisizeTestViewController(), animated: true)
    }
}
