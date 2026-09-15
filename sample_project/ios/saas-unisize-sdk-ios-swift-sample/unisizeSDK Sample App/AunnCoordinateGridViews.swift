import UIKit
import unisizeSDK

/*
 * aunn コーデ一覧の 2 カラムグリッド表示用の共通部品です（Android 版 GRID_COLUMN_COUNT = 2 相当）。
 * ホストアプリがネイティブ描画する例として、サンプル両画面から共有します。
 */

enum AunnCoordinateGrid {
    /// コーデ一覧のグリッド列数です。
    static let columnCount = 2
    static let interitemSpacing: CGFloat = 8
    static let lineSpacing: CGFloat = 8
    static let sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    /// コーデ画像の縦横比（幅:高さ）。ファッション写真向けの縦長です。
    static let imageAspectRatio: CGFloat = 3.0 / 4.0
    /// 写真下のスタッフ情報行（丸型アイコン＋テキスト 3 行）の高さです。
    static let infoHeight: CGFloat = 48
    static let staffIconSize: CGFloat = 40
    static let cellPadding: CGFloat = 4
    static let moreFooterHeight: CGFloat = 44
    static let cellReuseId = "AunnCoordinateCell"
    static let moreFooterReuseId = "AunnMoreFooter"

    /// コーデ一覧用の FlowLayout を生成します（フッターは hasMore のとき呼び出し側で高さを設定します）。
    static func makeLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = interitemSpacing
        layout.minimumLineSpacing = lineSpacing
        layout.sectionInset = sectionInset
        layout.footerReferenceSize = .zero
        return layout
    }

    /// セル 1 個のサイズを、コレクションビューの幅から 2 カラムぶんに割り付けて算出します。
    /// 高さは「余白 + 画像（3:4）+ スタッフ情報行」の合計です。
    static func itemSize(for collectionView: UICollectionView) -> CGSize {
        let inset = sectionInset.left + sectionInset.right
        let spacing = interitemSpacing * CGFloat(columnCount - 1)
        let width = max(0, floor((collectionView.bounds.width - inset - spacing) / CGFloat(columnCount)))
        let imageHeight = width * (1.0 / imageAspectRatio)
        let height = cellPadding * 2 + imageHeight + infoHeight
        return CGSize(width: width, height: height)
    }
}

/// コーデ 1 件分のセル（コーデ画像＋スタッフ情報行）です。
/// 写真下は、左に丸型のスタッフアイコン、右にショップ名／スタッフ名+身長／bodyType+personalColor の
/// 3 行を表示します。
final class AunnCoordinateCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let staffImageView = UIImageView()
    private let shopLabel = UILabel()
    private let staffLabel = UILabel()
    private let attributeLabel = UILabel()

    /// 写真タップ時のコールバックです（コーデ詳細画面への遷移用）。
    /// 設定された画面でのみ写真タップを有効にします（未設定なら従来どおりセル選択に届きます）。
    var onPhotoTapped: (() -> Void)? {
        didSet { imageView.isUserInteractionEnabled = onPhotoTapped != nil }
    }

    /// スタッフアイコンタップ時のコールバックです（スタッフ画面への遷移用）。
    /// 設定された画面でのみアイコンタップを有効にします（未設定なら従来どおりセル選択に届きます）。
    var onStaffIconTapped: (() -> Void)? {
        didSet { staffImageView.isUserInteractionEnabled = onStaffIconTapped != nil }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .secondarySystemBackground
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(photoTapped)))

        // スタッフアイコンは丸くクリップして表示します
        staffImageView.contentMode = .scaleAspectFill
        staffImageView.clipsToBounds = true
        staffImageView.backgroundColor = .secondarySystemBackground
        staffImageView.layer.cornerRadius = AunnCoordinateGrid.staffIconSize / 2
        staffImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(staffIconTapped)))

        for label in [shopLabel, staffLabel, attributeLabel] {
            label.font = .systemFont(ofSize: 10)
            label.numberOfLines = 1
        }
        attributeLabel.textColor = .secondaryLabel

        let textStack = UIStackView(arrangedSubviews: [shopLabel, staffLabel, attributeLabel])
        textStack.axis = .vertical
        textStack.spacing = 1

        let infoRow = UIStackView(arrangedSubviews: [staffImageView, textStack])
        infoRow.axis = .horizontal
        infoRow.spacing = 6
        infoRow.alignment = .center
        infoRow.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(imageView)
        contentView.addSubview(infoRow)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: AunnCoordinateGrid.cellPadding),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AunnCoordinateGrid.cellPadding),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AunnCoordinateGrid.cellPadding),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1.0 / AunnCoordinateGrid.imageAspectRatio),

            staffImageView.widthAnchor.constraint(equalToConstant: AunnCoordinateGrid.staffIconSize),
            staffImageView.heightAnchor.constraint(equalToConstant: AunnCoordinateGrid.staffIconSize),

            infoRow.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            infoRow.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: AunnCoordinateGrid.cellPadding),
            infoRow.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -AunnCoordinateGrid.cellPadding),
            infoRow.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -AunnCoordinateGrid.cellPadding),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// セル再利用時に前回の内容を確実に消します（非同期の画像読込による表示崩れを防ぐため）。
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        imageView.accessibilityIdentifier = nil
        staffImageView.image = nil
        staffImageView.accessibilityIdentifier = nil
        shopLabel.text = nil
        staffLabel.text = nil
        attributeLabel.text = nil
        onPhotoTapped = nil
        onStaffIconTapped = nil
    }

    @objc private func photoTapped() {
        onPhotoTapped?()
    }

    @objc private func staffIconTapped() {
        onStaffIconTapped?()
    }

    /// API から取得したコーデ 1 件をセルへ反映します。
    /// 画像は URL のみ返るため、ホストアプリ側で読み込んで表示します（ここではサンプル用の簡易ローダーを使用）。
    func configure(with item: AunnCoordinateItem) {
        shopLabel.text = item.shop.name
        staffLabel.text = "\(Self.displayStaffName(item.staff.name)) \(item.staff.height)cm"
        attributeLabel.text = [item.staff.bodyType, item.staff.personalColor]
            .compactMap { $0 }
            .joined(separator: " / ")
        SampleImageLoader.load(urlString: item.imgUrl, into: imageView)
        SampleImageLoader.load(urlString: item.staff.imgUrl, into: staffImageView)
    }

    /// スタッフ名の【...】部分（注記）を除いた表示用の名前を返します。
    private static func displayStaffName(_ name: String) -> String {
        return name
            .replacingOccurrences(of: "【[^】]*】", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}

/// 「すべて見る」フッターです（web の more リンク相当・クリック計測確認用）。
final class AunnCoordinateMoreFooterView: UICollectionReusableView {
    let button = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        button.setTitle("すべて見る", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
