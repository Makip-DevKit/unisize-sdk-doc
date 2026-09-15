import UIKit

/*
 * サンプル用の簡易画像ローダー（ライブラリ非依存）。
 * URL の画像をバックグラウンドで取得し、メインスレッドで UIImageView に表示します。
 * Android 版 SampleImageLoader に相当します。実アプリでは SDWebImage / Kingfisher 等の利用を想定しています。
 */
enum SampleImageLoader {
    private static let cache = NSCache<NSString, UIImage>()
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 15
        return URLSession(configuration: config)
    }()

    /// url の画像を imageView に表示します。取得に失敗した場合はプレースホルダのままにします。
    static func load(urlString: String, into imageView: UIImageView) {
        guard !urlString.isEmpty, let url = URL(string: urlString) else {
            return
        }
        // 読込完了前に同じ ImageView が別 URL へ使い回された場合の取り違えを防ぎます
        imageView.accessibilityIdentifier = urlString
        if let cached = cache.object(forKey: urlString as NSString) {
            imageView.image = cached
            return
        }
        session.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = UIImage(data: data) else {
                return
            }
            cache.setObject(image, forKey: urlString as NSString)
            DispatchQueue.main.async {
                guard imageView.accessibilityIdentifier == urlString else {
                    return
                }
                imageView.image = image
            }
        }.resume()
    }
}
