import UIKit
import unisizeSDK

/*
 * aunn パーソナライズ SDK と unisize バナー SDK を同一画面に同居させた検証用画面
 *
 * 商品詳細ページを想定し、上部に unisize バナー（TEXT）、その下に aunn のコーデ一覧を並べます。
 * beid は両 SDK で共有され（UnisizeBeidStore）、体型登録の反映は
 * 「同一 beid で相手側を再ロード → サーバーが最新値を返す」ホスト駆動リロード方式で行います。
 *
 * - 順方向: aunn で体型登録完了 → コーデ再取得（reload）に加え unisizeBanner.reload() を呼び、バナーも最新化します。
 *   バナーは UnisizeBanner（ラッパー）ではなく UnisizeBannerWebview を直接配置しています。
 * - 逆方向: unisize で体型登録/サイズレコメンド → didBeidChanged で coordinate.reload() を呼び、
 *   aunn コーデ（体型マッチ順・登録バナー表示）を最新化します。
 *   beid/属性はキャッシュ対象外のため reload() だけで鮮度が担保されます。
 *
 * cid / cuid / itemId は画面の入力欄から変更できます（既定値は defaultCid / defaultItemId）。
 * これらは aunn・unisize 双方で有効な値である必要があります。
 */
final class AunnCoordinateWithUnisizeTestViewController: UIViewController {

    // 入力欄の既定値
    private let defaultCid = "" // クライアントID
    private let defaultItemId = "" // 商品識別ID
    private let defaultCoordinateCount = 6

    /// cuid 入力欄のヒントです。cuid は未入力を既定とし、入力されたときだけ送信します。
    /// （cuid を送ると体型推定が働き、レコメンドの種別が変わります）
    private let cuidHint = "未入力なら送信しません"

    /// aunn コーデ取得・計測の本体です。
    private let coordinate = AunnCoordinate()
    // バナーは公開ラッパー（UnisizeBanner）ではなく UnisizeBannerWebview を直接配置します。
    // ラッパーが代行していた高さ制御はホスト側（didResized）で行い、その代わりに
    // ラッパーが転送していない didBannerClicked（バナークリック）も受け取れます。
    private var unisizeBanner: UnisizeBannerWebview?
    /// didLoad で受け取ったコーデ一覧（画面の描画元データ）です。
    private var items: [AunnCoordinateItem] = []
    /// コーデ一覧の取得を開始済み、または一覧を表示済みかどうかです。
    /// 逆方向連携（unisize の beid 変更で再取得）は、この画面が一覧を扱っている間だけ行います。
    /// 「コーデ取得（load）」だけでなく、体型登録完了の再取得で一覧が出た場合も対象にするため
    /// didLoad でも立てます。
    private var hasLoadedCoordinates = false

    // 検証パラメータの入力欄です。テストケースごとの値をビルドし直さずに切り替えられるようにしています。
    // aunn へは「コーデ取得（load）」、unisize バナーへは「unisize バナー再表示」で反映します。
    private let cidField = UITextField()
    private let cuidField = UITextField()
    private let itemIdField = UITextField()
    private let statusLabel = UILabel()
    // コーデ取得中に表示するローディング（ホスト側で表示制御。SDK は開始/終了をコールバックで通知しません）
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let textBannerRect = UIView()
    // バナーの高さは SDK からの didResized を受けてホストが更新します（ラッパー利用時は SDK 側が実施）。
    private var bannerHeightConstraint: NSLayoutConstraint?
    private let measurementButton = UIButton(type: .system)
    // 体型登録バナー相当の 1 行（web の登録バナー＋並べ替えチェックボックス相当）。
    // 左は並べ替えラベル＋体型マッチ ON/OFF トグル（登録済みのみ表示）、右は登録/変更ボタン。
    // ラベル・ボタンの文言は didLoad で出し分け、トグル切替後は reload() で再取得します。
    private let bodyMatchingRow = UIStackView()
    private let bodyMatchingLabel = UILabel()
    private let bodyMatchingSwitch = UISwitch()
    // ホストアプリがネイティブ描画する例（2 カラムのグリッド表示・コーデ画像付き）
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: AunnCoordinateGrid.makeLayout())
        view.backgroundColor = .systemBackground
        view.dataSource = self
        view.delegate = self
        view.register(AunnCoordinateCell.self, forCellWithReuseIdentifier: AunnCoordinateGrid.cellReuseId)
        view.register(
            AunnCoordinateMoreFooterView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
            withReuseIdentifier: AunnCoordinateGrid.moreFooterReuseId
        )
        return view
    }()
    private var showsMoreFooter = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "aunn + unisize"
        view.backgroundColor = .systemBackground
        setupLayout()

        // 長押し = API 取得データの詳細確認（アラート + コンソール全ダンプ）。
        // 短タップの Click 計測とは役割を分けています。
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(cellLongPressed(_:)))
        collectionView.addGestureRecognizer(longPress)

        // 商品詳細ページ相当。unisize が beid を発行するため item-detail で解決します。
        coordinate.delegate = self
        applyAunnParam()

        // unisize バナーを表示します（体型登録の反映確認は didBeidChanged 経由）。
        unisizeBanner = buildUnisizeBanner()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // 破棄は他サンプルと同じく viewDidDisappear で行います（deinit は pop 後の実行タイミングが不定なため）。
        // ただし別の画面を重ねただけのときもここへ来る場合があるので、
        // 実際に画面を離れるとき（pop / dismiss）だけ破棄します。完了後に reload() で再利用するためです。
        // （体型登録シートはシート表示のため viewDidDisappear 自体が呼ばれません。）
        guard isMovingFromParent || isBeingDismissed else {
            return
        }
        coordinate.stopCoordinateViewTimeTracking()
        teardownUnisizeBanner()
    }

    /// 入力欄の cid です。未入力のときは既定値へ戻します（cid は必須のため空にできません）。
    private func inputCid() -> String {
        let value = cidField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? defaultCid : value
    }

    /// 入力欄の cuid です。未入力のときは送信しません。
    private func inputCuid() -> String? {
        let value = cuidField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    /// 入力欄の itemId です。この画面は item-detail 固定のため、未入力のときは既定値へ戻します。
    private func inputItemId() -> String {
        let value = itemIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? defaultItemId : value
    }

    /// 入力欄の内容で aunn の起動パラメータを組み立てます。
    /// この画面は商品詳細相当のため pageType は item-detail 固定で、itemId が必須です。
    private func applyAunnParam() {
        coordinate.setupParam(
            AunnCoordinate.Param(
                cid: inputCid(),
                pageType: .itemDetail,
                coordinateCount: defaultCoordinateCount,
                itemId: inputItemId(),
                cuid: inputCuid(),
                enablePrintLog: true
            )
        )
    }

    /// unisize バナーを入力欄の内容で作り直します。
    /// バナーの cid / itm / cuid は setupParam で確定するため、値を変えるには作り直しが必要です。
    /// 古いインスタンスは WebView を残さないよう close() で破棄します。
    private func rebuildUnisizeBanner() {
        print("AunnWithUnisize > button: unisize バナー再表示 cid=\(inputCid())"
              + " cuid=\(inputCuid() ?? "nil") itemId=\(inputItemId())")
        view.endEditing(true)
        teardownUnisizeBanner()
        // 新しいバナーの高さは didResized で設定し直すため、いったん畳んでおきます
        collapseBannerRect()
        unisizeBanner = buildUnisizeBanner()
    }

    /// バナーを破棄します。close() は delegate / parentView も解放するため、
    /// これでホストとの相互参照が切れます。ビュー階層からも取り外します。
    private func teardownUnisizeBanner() {
        unisizeBanner?.close()
        unisizeBanner?.removeFromSuperview()
        unisizeBanner = nil
    }

    /// aunn と同居させる unisize バナー（TEXT）を入力欄の内容で生成します。
    /// UnisizeBanner を介さないため、配置・パラメータ設定・読み込み開始をホストが行います。
    private func buildUnisizeBanner() -> UnisizeBannerWebview {
        let banner = UnisizeBannerWebview(frame: .zero)
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.delegate = self
        // バナー領域いっぱいに広げます。領域自体の高さは didResized で更新します。
        textBannerRect.addSubview(banner)
        NSLayoutConstraint.activate([
            banner.topAnchor.constraint(equalTo: textBannerRect.topAnchor),
            banner.leadingAnchor.constraint(equalTo: textBannerRect.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: textBannerRect.trailingAnchor),
            banner.bottomAnchor.constraint(equalTo: textBannerRect.bottomAnchor),
        ])
        // この画面はテキストバナーのみのため bannerType / bannerMode とも "text" です
        banner.setupParam(
            parentView: self,
            bannerType: "text",
            bannerMode: "text",
            cid: inputCid(),
            itm: inputItemId(),
            cuid: inputCuid() ?? "",
            lang: "ja",
            enableWebViewLog: false,
            enablePrintLog: true,
            sendErrorLog: true,
            delegate: self
        )
        // UnisizeBanner は生成時に読み込みまで行うため、直接利用ではここで show() します
        banner.show()
        return banner
    }

    // MARK: - Layout

    private func setupLayout() {
        // 検証パラメータの入力欄です。値の変更は「コーデ取得」実行時に読み取ります。
        cidField.text = defaultCid
        cidField.borderStyle = .roundedRect
        cidField.autocapitalizationType = .none
        cidField.autocorrectionType = .no
        cidField.clearButtonMode = .whileEditing
        let cidRow = makeLabeledInputRow(label: "cid：", field: cidField)

        cuidField.placeholder = cuidHint
        cuidField.borderStyle = .roundedRect
        cuidField.autocapitalizationType = .none
        cuidField.autocorrectionType = .no
        cuidField.clearButtonMode = .whileEditing
        let cuidRow = makeLabeledInputRow(label: "cuid：", field: cuidField)

        itemIdField.text = defaultItemId
        itemIdField.borderStyle = .roundedRect
        itemIdField.autocapitalizationType = .none
        itemIdField.autocorrectionType = .no
        itemIdField.clearButtonMode = .whileEditing
        let itemIdRow = makeLabeledInputRow(label: "itemId：", field: itemIdField)

        statusLabel.text = "aunn + unisize 同居デモ"
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 13)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.setContentHuggingPriority(.required, for: .horizontal)
        let statusRow = UIStackView(arrangedSubviews: [statusLabel, loadingIndicator])
        statusRow.axis = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .center

        let bannerCaption = UILabel()
        bannerCaption.text = "▼ unisize バナー"
        bannerCaption.font = .systemFont(ofSize: 13)

        textBannerRect.translatesAutoresizingMaskIntoConstraints = false
        // 読み込み前は高さ 0 で畳んでおき、didResized を受けて広げます
        let heightConstraint = textBannerRect.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        bannerHeightConstraint = heightConstraint

        // 入力欄の変更をバナーへ反映するには作り直しが必要なため、専用のボタンを置きます
        let bannerReloadButton = UIButton(type: .system)
        bannerReloadButton.setTitle("unisize バナー再表示（入力反映）", for: .normal)
        bannerReloadButton.addTarget(self, action: #selector(bannerReloadTapped), for: .touchUpInside)

        let loadButton = UIButton(type: .system)
        loadButton.setTitle("コーデ取得（load）", for: .normal)
        loadButton.addTarget(self, action: #selector(loadTapped), for: .touchUpInside)

        // 体型登録バナー相当の 1 行。登録状況はコーデ取得まで不明なため、
        // 初期はラベル空・トグル非表示・ボタン "-" で、didLoad で更新します。
        measurementButton.setTitle("-", for: .normal)
        measurementButton.addTarget(self, action: #selector(measurementTapped), for: .touchUpInside)
        bodyMatchingLabel.font = .systemFont(ofSize: 13)
        // 背景色（#fafafa）は端末のダークモードでも固定のため、文字色も濃色で固定します
        bodyMatchingLabel.textColor = UIColor(red: 0x33 / 255.0, green: 0x33 / 255.0, blue: 0x33 / 255.0, alpha: 1)
        bodyMatchingSwitch.addTarget(self, action: #selector(bodyMatchingToggled), for: .valueChanged)
        bodyMatchingSwitch.isHidden = true
        bodyMatchingRow.axis = .horizontal
        bodyMatchingRow.spacing = 8
        bodyMatchingRow.alignment = .center
        bodyMatchingRow.backgroundColor = UIColor(red: 0xFA / 255.0, green: 0xFA / 255.0, blue: 0xFA / 255.0, alpha: 1)
        bodyMatchingRow.isLayoutMarginsRelativeArrangement = true
        bodyMatchingRow.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        bodyMatchingRow.addArrangedSubview(bodyMatchingLabel)
        bodyMatchingRow.addArrangedSubview(bodyMatchingSwitch)
        bodyMatchingRow.addArrangedSubview(UIView())
        bodyMatchingRow.addArrangedSubview(measurementButton)

        // 体型登録バナー行はコーデ一覧の直上に置きます
        let header = UIStackView(arrangedSubviews: [
            cidRow, cuidRow, itemIdRow, statusRow, bannerCaption, textBannerRect, bannerReloadButton,
            loadButton, bodyMatchingRow,
        ])
        header.axis = .vertical
        header.spacing = 12
        header.translatesAutoresizingMaskIntoConstraints = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(header)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            collectionView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    /// ラベルと入力欄を「ラベル：入力欄」の横並び 1 行にまとめた行を生成します（入力欄が残り幅に広がります）。
    private func makeLabeledInputRow(label: String, field: UITextField) -> UIStackView {
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 13)
        labelView.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [labelView, field])
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        return row
    }

    // MARK: - Actions

    @objc private func cellLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        // 長押しで、API から取得したコーデ 1 件の全項目（レコメンド根拠の `v` を含む）を
        // アラート表示し、コンソールにも全ダンプします。
        CoordinateDetailDialog.show(from: self, tag: "AunnWithUnisize", item: items[indexPath.item])
    }

    /// 「unisize バナー再表示」ボタン。入力欄の値を反映するためバナーを作り直します。
    @objc private func bannerReloadTapped() {
        rebuildUnisizeBanner()
    }

    /// 「コーデ取得（load）」ボタン。入力欄の内容をパラメータへ反映してから load() します。
    @objc private func loadTapped() {
        view.endEditing(true)
        // 入力欄の変更を毎回反映してから取得します
        applyAunnParam()
        hasLoadedCoordinates = true
        statusLabel.text = "取得中…"
        showLoading()
        coordinate.load()
    }

    /// 体型マッチ ON/OFF トグル。切り替えを SDK へ伝えたうえで reload() し、並び順を取り直します。
    @objc private func bodyMatchingToggled() {
        print("AunnWithUnisize > switch: toggleBodyMatching=\(bodyMatchingSwitch.isOn)")
        coordinate.toggleBodyMatching(enabled: bodyMatchingSwitch.isOn)
        statusLabel.text = "体型マッチ切替: \(bodyMatchingSwitch.isOn) → 再取得します"
        showLoading()
        coordinate.reload()
    }

    /// 「すべて見る」フッター。この画面ではクリック計測の送信のみ行います。
    @objc private func moreTapped() {
        print("AunnWithUnisize > button: すべて見るクリック計測")
        coordinate.sendMoreLinkClickEvent()
        statusLabel.text = "クリック計測: すべて見る (more)"
    }

    /// 体型登録／変更ボタン。体型登録アプリ（AunnCoordinateMeasurement）をシート表示します。
    /// 登録完了時は aunn と unisize バナーの両方を再ロードし、順方向の連携を確認できるようにしています。
    @objc private func measurementTapped() {
        // 測定アプリ表示中は表示時間計測（time=3000）を止めます（Web 版の isOnEnquete 相当）
        coordinate.pauseCoordinateViewTimeTracking()
        let measurementVC = AunnCoordinateMeasurementViewController(
            cid: inputCid(),
            itemId: inputItemId(),
            cuid: inputCuid(),
            pageType: .itemDetail
        )
        measurementVC.onCompleted = { [weak self] in
            guard let self = self else { return }
            self.statusLabel.text = "体型登録完了 → aunn・unisize を再取得します"
            // aunn コーデを再取得します
            self.showLoading()
            self.coordinate.reload()
            // 順方向連携: 同居する unisize バナーも同一 beid で再ロードします。
            self.unisizeBanner?.reload()
        }
        measurementVC.onFailed = { [weak self] error in
            self?.statusLabel.text = "体型登録エラー: \(error.errorCode.rawValue) \(error.errorCode.getMessage())"
        }
        // 完了・閉じる・スワイプダウンのどの経路でも、閉じたら計測を再開します
        measurementVC.onDismissed = { [weak self] in
            self?.coordinate.resumeCoordinateViewTimeTracking()
        }
        present(measurementVC, animated: true)
    }

    /// hasMore のときだけリスト末尾に「すべて見る」を表示します（web の more リンク相当）。
    /// この画面ではタップしてもクリック計測のみ送信します。
    /// コーデ一覧画面への遷移は aunn 単独の検証画面（pageType に「商品詳細ページ」を選択）で確認できます。
    private func updateMoreFooter(hasMore: Bool) {
        showsMoreFooter = hasMore
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = hasMore
                ? CGSize(width: collectionView.bounds.width, height: AunnCoordinateGrid.moreFooterHeight)
                : .zero
        }
    }

    /// コーデ取得（load/reload）の直前に呼びます。終了は didLoad / didFail で hideLoading() します。
    private func showLoading() {
        loadingIndicator.startAnimating()
    }

    private func hideLoading() {
        loadingIndicator.stopAnimating()
    }

    /// バナーが表示できないとき（didFail / didUnsupported）は領域を高さ 0 に畳みます
    /// （Android 版と同じホスト側処理）。
    private func collapseBannerRect() {
        updateBannerHeight(0)
    }

    /// バナー領域の高さを更新します（UnisizeBanner 利用時に SDK 側が行っていた処理）。
    private func updateBannerHeight(_ height: CGFloat) {
        DispatchQueue.main.async {
            self.bannerHeightConstraint?.constant = height
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - AunnCoordinateDelegate

extension AunnCoordinateWithUnisizeTestViewController: AunnCoordinateDelegate {

    /// コーデ取得成功時に呼ばれます。受け取った一覧をホストアプリ側で描画し、
    /// 表示できたら Page View 計測と表示時間計測を開始します。
    func aunnCoordinate(_ coordinate: AunnCoordinate,
                        didLoad coordinates: [AunnCoordinateItem],
                        recType: AunnCoordinateRecommendAlgorithm,
                        hasMore: Bool,
                        isBodyRegistered: Bool,
                        isBodyAndPreferenceSort: Bool) {
        hideLoading()
        hasLoadedCoordinates = true
        items = coordinates
        updateMoreFooter(hasMore: hasMore)
        collectionView.reloadData()
        // ボタンは登録/変更のみ（web の登録・変更ボタン相当）。
        let bannerLabel = isBodyRegistered ? "変更" : "登録"
        measurementButton.setTitle(bannerLabel, for: .normal)
        // 体型マッチのトグルは登録済みのときだけ表示。登録済みのラベルは体型×協調かで出し分けます（web と同一）。
        if isBodyRegistered {
            bodyMatchingLabel.text = isBodyAndPreferenceSort ? "体型と好みで並べ替え" : "体型で並べ替え"
            // setOn はアクションを発火しないため、Android 版のような抑止フラグは不要です
            bodyMatchingSwitch.setOn(coordinate.useBodyMatching, animated: false)
            bodyMatchingSwitch.isHidden = false
        } else {
            bodyMatchingLabel.text = "あなたの体型で並べ替え"
            bodyMatchingSwitch.isHidden = true
        }
        statusLabel.text = "取得成功: \(coordinates.count) 件 / recType=\(recType.value) / バナー=\(bannerLabel)"
        if !coordinates.isEmpty {
            coordinate.sendCoordinateViewEvent(recType: recType)
            // リストが画面内に 50% 以上・3 秒間表示されたら time=3000 の View 計測を自動送信します
            coordinate.startCoordinateViewTimeTracking(view: collectionView, recType: recType)
        }
    }

    /// beid（unisize と共有するユーザー識別子）が変わったときに呼ばれます。
    func aunnCoordinate(_ coordinate: AunnCoordinate, didChangeBeid beid: String) {
        print("AunnWithUnisize > coordinate > didChangeBeid: \(beid)")
    }

    /// コーデ取得失敗時に呼ばれます。実アプリではコーデ一覧の枠ごと非表示にする想定です。
    func aunnCoordinate(_ coordinate: AunnCoordinate, didFail error: UnisizeError) {
        hideLoading()
        statusLabel.text = "エラー: \(error.errorCode.rawValue) \(error.errorCode.getMessage())"
    }
}

// MARK: - UnisizeBannerWebviewDelegate
// UnisizeBanner（ラッパー）ではなく UnisizeBannerWebview を直接使うため、
// 受け取るのは UnisizeBannerWebviewDelegate です。ラッパー用の UnisizeBannerDelegate と同じく
// SDK の公開プロトコルなので、ホストアプリから実装して差し支えありません。
// ラッパー経由では届かない didBannerClicked（バナークリック）もここで受け取れます。
//
// 全メソッドが @objc optional のため、シグネチャを間違えてもコンパイルは通り、
// 単に呼ばれなくなります。追加・変更するときは SDK 側の宣言と突き合わせてください。

extension AunnCoordinateWithUnisizeTestViewController: UnisizeBannerWebviewDelegate {
    /// バナーの表示完了時に呼ばれます。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didFinish message: String, bannerType: String) {
        print("AunnWithUnisize > unisizeBanner > didFinish: bannerType=\(bannerType)")
    }

    /// バナーの実寸が確定したら領域の高さを合わせます（UnisizeBanner 利用時は SDK 側が行う処理）。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview,
                              didResized message: String,
                              width: CGFloat,
                              height: CGFloat,
                              bannerType: String) {
        print("AunnWithUnisize > unisizeBanner > didResized: bannerType=\(bannerType) width=\(width) height=\(height)")
        updateBannerHeight(height)
    }

    /// バナークリック。UnisizeBanner 経由では転送されないため、直接利用でのみ受け取れます。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didBannerClicked message: String, bannerType: String) {
        print("AunnWithUnisize > unisizeBanner > bannerClicked: bannerType=\(bannerType)")
    }

    func unisizeBannerWebview(_ banner: UnisizeBannerWebview,
                              didBeidChanged beid: String,
                              recommendedItems: String,
                              bannerType: String) {
        // 逆方向連携: unisize 側の体型登録/サイズレコメンドを aunn へ反映します。
        print("AunnWithUnisize > unisizeBanner > didBeidChanged: beid=\(beid) type=\(bannerType)")
        DispatchQueue.main.async {
            // 反映先の一覧をまだ取得していないときは取りに行きません。
            // reload() は load() と同じくコーデ取得と Page View 計測まで行うため、
            // 「コーデ取得」を押す前に一覧の取得と計測が走らないようにしています。
            guard self.hasLoadedCoordinates else {
                self.statusLabel.text = "unisize 側で beid 変更（「コーデ取得」を押すと反映されます）"
                return
            }
            print("AunnWithUnisize > coordinate.reload()（beid 変更を反映）")
            self.showLoading()
            self.coordinate.reload()
        }
    }

    /// バナーの表示失敗時に呼ばれます。表示できないため領域を畳みます。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didFail errorObj: UnisizeError, bannerType: String) {
        print("AunnWithUnisize > unisizeBanner > didFail: \(errorObj.errorCode.getMessage())")
        collapseBannerRect()
    }

    /// unisize の対象外商品だった場合に呼ばれます。表示しないため領域を畳みます。
    func unisizeBannerWebview(_ banner: UnisizeBannerWebview, didUnsupported message: String) {
        print("AunnWithUnisize > unisizeBanner > didUnsupported: \(message)")
        collapseBannerRect()
    }
}

// MARK: - UICollectionView（コーデ一覧のネイティブ描画）

extension AunnCoordinateWithUnisizeTestViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AunnCoordinateGrid.cellReuseId,
            for: indexPath
        ) as! AunnCoordinateCell
        cell.configure(with: items[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let footer = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: AunnCoordinateGrid.moreFooterReuseId,
            for: indexPath
        ) as! AunnCoordinateMoreFooterView
        footer.button.removeTarget(nil, action: nil, for: .allEvents)
        footer.button.addTarget(self, action: #selector(moreTapped), for: .touchUpInside)
        footer.isHidden = !showsMoreFooter
        return footer
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return AunnCoordinateGrid.itemSize(for: collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.item]
        coordinate.sendCoordinateLinkClickEvent(coordinateId: item.id, staffId: item.staff.id)
        statusLabel.text = "クリック計測: coordinate=\(item.id), staff=\(item.staff.id)"
    }
}
