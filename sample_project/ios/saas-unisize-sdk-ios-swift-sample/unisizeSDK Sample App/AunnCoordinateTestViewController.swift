import UIKit
import unisizeSDK

/*
 * aunn パーソナライズ SDK の検証用画面
 *
 * コーデ一覧の取得（ネイティブ描画）→ 体型登録アプリ（WKWebView）→ 完了で再取得、
 * さらにコーデ詳細相当の View 計測までを一画面で確認できます。
 * cid / cuid / itemId は画面の入力欄から変更できます。（既定値は defaultCid / defaultItemId）
 *
 * 実装の流れは次の 3 ステップです。
 *  1. AunnCoordinate を生成し、delegate と setupParam()（cid / pageType / coordinateCount など）を設定する
 *  2. load() を呼び、delegate の didLoad で受け取ったコーデ一覧をホストアプリ側で描画する
 *  3. 表示・クリックの計測（sendCoordinateViewEvent / sendCoordinateLinkClickEvent など）を送信する
 *
 * ※ コーデ一覧の UI は SDK ではなくホストアプリが描画します（本サンプルは UICollectionView の 2 カラム表示）。
 */
final class AunnCoordinateTestViewController: UIViewController {

    // 入力欄の既定値
    private let defaultCid = "" // クライアントID
    private let defaultItemId = "" // 商品識別ID
    private let defaultCoordinateCount = 6
    /// 「すべて見る」ボタンの遷移先「コーデ一覧」画面の表示件数です。
    private let moreListCoordinateCount = 100

    /// cuid 入力欄のヒントです。cuid は未入力を既定とし、入力されたときだけ送信します。
    /// （cuid を送ると体型推定が働き、レコメンドの種別が変わります）
    private let cuidHint = "未入力なら送信しません"

    /// 商品詳細ページで unisize バナーの beid 発行を待つ上限です。
    /// この画面は aunn 単独（unisize バナーを配置していない）ため、待っても beid は発行されません。
    /// 既定の 3 秒のままだと商品詳細を選ぶたびにタイムアウト分だけ表示が遅れるので、待機を無効化します。
    /// unisize と同居する画面（`AunnCoordinateWithUnisizeTestViewController`）では既定値のまま待たせる必要があります。
    private static let unisizeBeidWaitMs = 0

    /// コーデ取得（表示タグ）向けの pageType と表示文言です（Android 版 DISPLAY_PAGE_TYPES と同一）。
    private let displayPageTypes: [(pageType: AunnCoordinatePageType, label: String)] = [
        (.top, "トップページ"),
        (.coordination, "コーディネート一覧（トップ経由）"),
        (.coordinationItem, "コーディネート一覧（商品詳細経由）"),
        (.itemDetail, "商品詳細ページ"),
    ]

    /// aunn コーデ取得・計測の本体です。1 画面につき 1 インスタンスを保持します。
    private let coordinate = AunnCoordinate()
    /// didLoad で受け取ったコーデ一覧（画面の描画元データ）です。
    private var items: [AunnCoordinateItem] = []
    /// 送信する pageType（どのページからの取得かを表します）です。
    private var selectedPageType: AunnCoordinatePageType = .top
    /// 体型登録済みかどうか（didLoad で通知され、登録/変更ボタンの文言に使います）。
    private var isBodyRegistered = false
    /// 体型に加えて好みでも並べ替えているかどうか（didLoad で通知され、ラベルの出し分けに使います）。
    private var isBodyAndPreferenceSort = false

    // 検証パラメータの入力欄
    private let cidField = UITextField()
    private let cuidField = UITextField()
    private let itemIdField = UITextField()
    
    private let statusLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)
    private let pageTypeButton = UIButton(type: .system)
    private let coordinateCountField = UITextField()
    private let measurementButton = UIButton(type: .system)
    // 体型登録バナー相当の 1 行（web の登録バナー＋並べ替えチェックボックス相当）。
    // 左は並べ替えラベル＋体型マッチ ON/OFF トグル（登録済みのみ表示）、右は登録/変更ボタン。
    // ラベル・ボタンの文言は didLoad で出し分け、トグル切替後は reload() で再取得します。
    private let bodyMatchingRow = UIStackView()
    private let bodyMatchingLabel = UILabel()
    private let bodyMatchingSwitch = UISwitch()
    private let coordinateIdField = UITextField()
    private let staffIdField = UITextField()
    // ホストアプリがネイティブ描画する例（2 カラムのグリッド表示・コーデ画像付き）。
    // リスト単体ではスクロールせず、全件ぶんの高さで展開します（スクロールは画面全体が担います）。
    private lazy var collectionView: UICollectionView = {
        let view = SelfSizingCollectionView(frame: .zero, collectionViewLayout: AunnCoordinateGrid.makeLayout())
        view.backgroundColor = .systemBackground
        view.isScrollEnabled = false
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

    /// 「すべて見る」からの遷移時に引き継ぐ初期表示設定です（通常起動時は nil）。
    /// 遷移先でも同じ条件で検証できるよう cid / cuid / itemId を引き継ぎ、入力欄に反映します
    /// （beid は共有ストア経由で引き継がれます）。
    /// itemId は商品詳細など item_id 付きの画面から遷移したとき、コーデ一覧のトラッキングへ引き継ぎます。
    private let initialListSetup: (pageType: AunnCoordinatePageType,
                                   coordinateCount: Int,
                                   cid: String,
                                   cuid: String?,
                                   itemId: String?)?

    /// 遷移元から引き継いだ item_id です（itemId 不要の pageType でもトラッキングに含めます）。
    private var inheritedItemId: String?

    init(initialListSetup: (pageType: AunnCoordinatePageType,
                            coordinateCount: Int,
                            cid: String,
                            cuid: String?,
                            itemId: String?)? = nil) {
        self.initialListSetup = initialListSetup
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "aunn テスト"
        view.backgroundColor = .systemBackground
        setupLayout()
        setupCoordinate()

        // 長押し = API 取得データの詳細確認（アラート + コンソール全ダンプ）。
        // 短タップの Click 計測とは役割を分けています。
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(cellLongPressed(_:)))
        collectionView.addGestureRecognizer(longPress)

        // 「すべて見る」からの遷移時は、指定の pageType / 件数を初期表示して自動取得します。
        // 遷移元の cid / cuid / itemId を入力欄へ復元し、同じ条件のまま検証を続けられるようにします
        // （beid は共有ストア経由で引き継がれます）。
        if let setup = initialListSetup {
            selectedPageType = setup.pageType
            inheritedItemId = setup.itemId
            cidField.text = setup.cid
            // cuid は未指定（nil）と空文字を区別せず、どちらも「送信しない」として空欄にします
            cuidField.text = setup.cuid ?? ""
            if let itemId = setup.itemId {
                itemIdField.text = itemId
            }
            rebuildPageTypeMenu()
            coordinateCountField.text = String(setup.coordinateCount)
            applyParam(coordinateCount: setup.coordinateCount)
            statusLabel.text = "取得中…（pageType: \(setup.pageType.value)）"
            showLoading()
            coordinate.load()
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        // 画面を離れるときは表示時間計測を打ち切ります。コーデ詳細・スタッフ画面へ push した
        // ときもここへ来るため、pop / dismiss のときだけ停止します。
        // （体型登録シートはシート表示のため viewDidDisappear 自体が呼ばれません。
        //   シート表示中の計測は pause / resume で制御します。）
        guard isMovingFromParent || isBeingDismissed else {
            return
        }
        coordinate.stopCoordinateViewTimeTracking()
    }

    /// cid 入力欄
    private func inputCid() -> String {
        let value = cidField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? defaultCid : value
    }

    /// cuid 入力欄
    private func inputCuid() -> String? {
        let value = cuidField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    /// itemId 入力欄
    private func inputItemId() -> String? {
        let value = itemIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return value.isEmpty ? nil : value
    }

    /// AunnCoordinate の初期設定です。delegate を設定し、既定のパラメータを流し込みます。
    private func setupCoordinate() {
        coordinate.delegate = self
        applyParam(coordinateCount: defaultCoordinateCount)
    }

    /// coordinateCount 入力値を返します。無効なら nil（呼び出し側でエラー表示します）。
    private func inputCoordinateCount() -> Int? {
        guard let count = Int(coordinateCountField.text ?? ""), count > 0 else { return nil }
        return count
    }

    /// 現在の pageType で送信する itemId です。itemId 必須の pageType は入力欄の値、
    /// それ以外は「すべて見る」遷移で引き継いだ item_id（なければ nil）を使います。
    private func effectiveItemId() -> String? {
        return selectedPageType.requiresItemId ? inputItemId() : inheritedItemId
    }

    /// 入力欄の内容から aunn の起動パラメータを組み立てて設定します。
    /// load() / reload() の前に呼び、入力の変更を毎回反映させます。
    private func applyParam(coordinateCount: Int) {
        coordinate.setupParam(
            AunnCoordinate.Param(
                cid: inputCid(),
                pageType: selectedPageType,
                coordinateCount: coordinateCount,
                itemId: effectiveItemId(),
                cuid: inputCuid(),
                enablePrintLog: true,
                unisizeBeidWaitMs: AunnCoordinateTestViewController.unisizeBeidWaitMs
            )
        )
    }

    // MARK: - Layout

    private func setupLayout() {
        // 検証パラメータの入力欄です。値の変更は「コーデ取得」など各操作の実行時に読み取ります。
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

        statusLabel.text = "「コーデ取得」を押してください"
        statusLabel.numberOfLines = 0
        statusLabel.font = .systemFont(ofSize: 13)

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.setContentHuggingPriority(.required, for: .horizontal)
        let statusRow = UIStackView(arrangedSubviews: [statusLabel, loadingIndicator])
        statusRow.axis = .horizontal
        statusRow.spacing = 8
        statusRow.alignment = .center

        pageTypeButton.contentHorizontalAlignment = .leading
        pageTypeButton.showsMenuAsPrimaryAction = true
        // タップでプルダウンを開き、選択中の項目がボタンのタイトルに反映されます
        pageTypeButton.changesSelectionAsPrimaryAction = true
        rebuildPageTypeMenu()

        let countLabel = UILabel()
        countLabel.text = "coordinateCount"
        countLabel.font = .systemFont(ofSize: 13)
        coordinateCountField.text = String(defaultCoordinateCount)
        coordinateCountField.keyboardType = .numberPad
        coordinateCountField.borderStyle = .roundedRect
        coordinateCountField.widthAnchor.constraint(equalToConstant: 80).isActive = true
        let countRow = UIStackView(arrangedSubviews: [countLabel, coordinateCountField, UIView()])
        countRow.axis = .horizontal
        countRow.spacing = 8
        countRow.alignment = .center

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

        // コーデ詳細 View 計測の検証導線です（セルタップでも送信しますが、任意の coordinateId を指定できます）。
        // ラベルと入力欄は「ラベル：入力欄」の横並び 1 行にまとめ、送信ボタンはその下に置きます。
        coordinateIdField.placeholder = "例: 12345"
        coordinateIdField.keyboardType = .numberPad
        coordinateIdField.borderStyle = .roundedRect
        let coordinateIdRow = makeLabeledInputRow(label: "coordinateId：", field: coordinateIdField)
        let coordinationDetailButton = UIButton(type: .system)
        coordinationDetailButton.setTitle("コーデ詳細 View 計測 (coordination-detail)", for: .normal)
        coordinationDetailButton.addTarget(self, action: #selector(coordinationDetailTapped), for: .touchUpInside)

        // スタッフ詳細 View 計測の検証導線です
        staffIdField.placeholder = "例: 678"
        staffIdField.keyboardType = .numberPad
        staffIdField.borderStyle = .roundedRect
        let staffIdRow = makeLabeledInputRow(label: "staffId：", field: staffIdField)
        let staffButton = UIButton(type: .system)
        staffButton.setTitle("スタッフ詳細 View 計測 (staff)", for: .normal)
        staffButton.addTarget(self, action: #selector(staffTapped), for: .touchUpInside)

        // 体型登録バナー行はコーデ一覧の直上に置きます
        let header = UIStackView(arrangedSubviews: [
            cidRow, cuidRow, itemIdRow, statusRow, pageTypeButton, countRow, loadButton,
            coordinateIdRow, coordinationDetailButton, staffIdRow, staffButton, bodyMatchingRow,
        ])
        header.axis = .vertical
        header.spacing = 8
        // ヘッダの左右余白はスタック側のマージンで確保します（コーデ一覧は全幅表示のため）
        header.isLayoutMarginsRelativeArrangement = true
        header.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)

        // ヘッダも固定せず、画面全体を 1 つのスクロールにまとめます（Android 版と同じ構成）
        let content = UIStackView(arrangedSubviews: [header, collectionView])
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
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

    /// プルダウンの項目を selectedPageType に合わせて作り直します（選択中の項目にチェックが付きます）。
    private func rebuildPageTypeMenu() {
        pageTypeButton.menu = UIMenu(children: displayPageTypes.map { entry in
            UIAction(title: entry.label, state: entry.pageType == selectedPageType ? .on : .off) { [weak self] _ in
                self?.pageTypeChanged(to: entry.pageType)
            }
        })
    }

    /// プルダウンで pageType が選ばれたときの処理です（値を保持して次回の取得へ反映します）。
    private func pageTypeChanged(to pageType: AunnCoordinatePageType) {
        selectedPageType = pageType
        applyParam(coordinateCount: inputCoordinateCount() ?? defaultCoordinateCount)
        let label = displayPageTypes.first(where: { $0.pageType == pageType })?.label ?? pageType.value
        statusLabel.text = "pageType: \(label)。「コーデ取得」を押してください"
    }

    /// 「コーデ取得（load）」ボタン。入力欄の内容をパラメータへ反映してから load() します。
    @objc private func loadTapped() {
        view.endEditing(true)
        guard let count = inputCoordinateCount() else {
            statusLabel.text = "coordinateCount は 1 以上の整数を指定してください"
            return
        }
        let itemId = effectiveItemId()
        print("AunnTest > button: コーデ取得 (load) cid=\(inputCid()) cuid=\(inputCuid() ?? "nil")"
              + " itemId=\(itemId ?? "nil") pageType=\(selectedPageType.value) coordinateCount=\(count)")
        applyParam(coordinateCount: count)
        statusLabel.text = "取得中…（pageType: \(selectedPageType.value)）"
        showLoading()
        coordinate.load()
    }

    /// 体型マッチ ON/OFF トグル。切り替えを SDK へ伝えたうえで reload() し、並び順を取り直します。
    @objc private func bodyMatchingToggled() {
        print("AunnTest > switch: toggleBodyMatching=\(bodyMatchingSwitch.isOn)")
        coordinate.toggleBodyMatching(enabled: bodyMatchingSwitch.isOn)
        statusLabel.text = "体型マッチ切替: \(bodyMatchingSwitch.isOn) → 再取得します"
        showLoading()
        coordinate.reload()
    }

    /// コーデ詳細の View 計測を任意の coordinateId で送信します。
    /// 一覧を経由せず単体で計測したいときの例として、AunnCoordinateTracking を直接使用します。
    @objc private func coordinationDetailTapped() {
        view.endEditing(true)
        guard let coordinateId = Int(coordinateIdField.text ?? "") else {
            statusLabel.text = "coordinateId は整数で指定してください"
            return
        }
        print("AunnTest > button: コーデ詳細 View 計測 coordinateId=\(coordinateId)")
        let tracking = AunnCoordinateTracking()
        tracking.setupParam(
            AunnCoordinateTracking.Param(
                cid: inputCid(),
                pageType: .coordinationDetail,
                cuid: inputCuid(),
                coordinateId: coordinateId,
                enablePrintLog: true
            )
        )
        tracking.send()
        statusLabel.text = "coordination-detail View ログを送信しました (coordinateId=\(coordinateId))"
    }

    /// スタッフ詳細の View 計測を任意の staffId で送信します（AunnCoordinateTracking を直接使用）。
    @objc private func staffTapped() {
        view.endEditing(true)
        guard let staffId = Int(staffIdField.text ?? "") else {
            statusLabel.text = "staffId は整数で指定してください"
            return
        }
        print("AunnTest > button: スタッフ詳細 View 計測 staffId=\(staffId)")
        let tracking = AunnCoordinateTracking()
        tracking.setupParam(
            AunnCoordinateTracking.Param(
                cid: inputCid(),
                pageType: .staff,
                cuid: inputCuid(),
                staffId: staffId,
                enablePrintLog: true
            )
        )
        tracking.send()
        statusLabel.text = "staff View ログを送信しました (staffId=\(staffId))"
    }

    /// 「すべて見る」フッター。クリック計測を送り、コーデ一覧の画面へ遷移します。
    @objc private func moreTapped() {
        // 新しい aunn テスト画面をコーデ一覧・100 件で開きます。
        // 商品詳細（item-detail）からの遷移は一覧（商品）タブ（coordination-item）、それ以外はコーデ一覧タブです。
        // item_id 付きの画面からの遷移では、遷移先のコーデ一覧のトラッキングへ item_id を引き継ぎます。
        let destinationPageType: AunnCoordinatePageType = selectedPageType == .itemDetail ? .coordinationItem : .coordination
        print("AunnTest > button: すべて見るクリック計測 → \(destinationPageType.value)（\(moreListCoordinateCount)件）を新規画面で表示")
        coordinate.sendMoreLinkClickEvent()
        statusLabel.text = "クリック計測: すべて見る (more)"
        let listVC = AunnCoordinateTestViewController(
            initialListSetup: (pageType: destinationPageType,
                               coordinateCount: moreListCoordinateCount,
                               cid: inputCid(),
                               cuid: inputCuid(),
                               itemId: effectiveItemId())
        )
        navigationController?.pushViewController(listVC, animated: true)
    }

    /// 体型登録／変更ボタン。体型登録アプリ（AunnCoordinateMeasurement）をシート表示します。
    /// 登録が完了したら reload() でコーデ一覧を取り直し、並び順・バナー表示を最新化します。
    @objc private func measurementTapped() {
        // オープン計測は AunnCoordinateMeasurement が自動送信します。
        // ログには実際に測定アプリへ渡す値を出します（itemId は pageType 依存のため、
        // 入力欄に値があっても itemId 不要の pageType では nil になります）。
        print("AunnTest > button: \(measurementButton.title(for: .normal) ?? "") cid=\(inputCid())"
              + " cuid=\(inputCuid() ?? "nil") itemId=\(effectiveItemId() ?? "nil")")
        // 測定アプリ表示中は表示時間計測（time=3000）を止めます（Web 版の isOnEnquete 相当）
        coordinate.pauseCoordinateViewTimeTracking()
        // pageType / itemId はコーデ取得と同じ値を渡します。体型登録バナーの
        // click / complete 計測にそのまま載るため、ここがずれるとコーデ取得側のログと
        // page・item_id が食い違います。
        let measurementVC = AunnCoordinateMeasurementViewController(
            cid: inputCid(),
            itemId: effectiveItemId(),
            cuid: inputCuid(),
            pageType: selectedPageType
        )
        measurementVC.onCompleted = { [weak self] in
            self?.statusLabel.text = "体型登録完了 → 再取得します"
            self?.showLoading()
            self?.coordinate.reload()
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
    /// タップしたときの処理は moreTapped() を参照してください。
    private func updateMoreFooter(hasMore: Bool) {
        showsMoreFooter = hasMore
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.footerReferenceSize = hasMore
                ? CGSize(width: collectionView.bounds.width, height: AunnCoordinateGrid.moreFooterHeight)
                : .zero
        }
    }

    // MARK: - 検証用ヘルパ

    /// コーデ取得（load/reload）の直前に呼びます。終了は didLoad / didFail で hideLoading() します。
    private func showLoading() {
        loadingIndicator.startAnimating()
    }

    private func hideLoading() {
        loadingIndicator.stopAnimating()
    }

    /// 写真タップでコーデ詳細画面へ遷移します。クリック計測（経由履歴の記録も兼ねます）を送り、
    /// コーデ詳細の View 計測（page=coordination-detail）は遷移先の表示完了時に送信します。
    private func openCoordinateDetail(_ item: AunnCoordinateItem) {
        print("AunnTest > cell: コーデ写真タップ coordinateId=\(item.id) staffId=\(item.staff.id) → 詳細画面へ")
        coordinate.sendCoordinateLinkClickEvent(coordinateId: item.id, staffId: item.staff.id)
        let detailVC = AunnCoordinateDetailViewController(
            cid: inputCid(),
            cuid: inputCuid(),
            coordinateId: item.id,
            imgUrl: item.imgUrl,
            staffId: item.staff.id
        )
        navigationController?.pushViewController(detailVC, animated: true)
    }

    /// スタッフアイコンタップでスタッフ画面へ遷移します。クリック計測（経由履歴の記録も兼ねます。
    /// スタッフ画面の計測は staffId で照合されます）を送り、
    /// スタッフの View 計測（page=staff）は遷移先の表示完了時に送信します。
    private func openStaffDetail(_ item: AunnCoordinateItem) {
        print("AunnTest > cell: スタッフアイコンタップ staffId=\(item.staff.id) → スタッフ画面へ")
        coordinate.sendCoordinateLinkClickEvent(coordinateId: item.id, staffId: item.staff.id)
        let staffVC = AunnCoordinateStaffDetailViewController(
            cid: inputCid(),
            cuid: inputCuid(),
            staffId: item.staff.id,
            staffImgUrl: item.staff.imgUrl
        )
        navigationController?.pushViewController(staffVC, animated: true)
    }

    /// セル長押しで、取得データの詳細確認ダイアログを開きます。
    @objc private func cellLongPressed(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        let point = gesture.location(in: collectionView)
        guard let indexPath = collectionView.indexPathForItem(at: point) else { return }
        showCoordinateDetail(items[indexPath.item])
    }

    /// 長押しで、API から取得したコーデ 1 件の全項目（レコメンド根拠の `v` を含む）を
    /// アラート表示し、コンソールにも全ダンプします。短タップの Click 計測とは役割を分けています。
    private func showCoordinateDetail(_ item: AunnCoordinateItem) {
        CoordinateDetailDialog.show(from: self, tag: "AunnTest", item: item)
    }
}

// MARK: - AunnCoordinateDelegate

extension AunnCoordinateTestViewController: AunnCoordinateDelegate {

    /// コーデ取得成功時に呼ばれます。受け取った一覧をホストアプリ側で描画し、
    /// 表示できたら Page View 計測と表示時間計測を開始します。
    func aunnCoordinate(_ coordinate: AunnCoordinate,
                        didLoad coordinates: [AunnCoordinateItem],
                        recType: AunnCoordinateRecommendAlgorithm,
                        hasMore: Bool,
                        isBodyRegistered: Bool,
                        isBodyAndPreferenceSort: Bool) {
        hideLoading()
        items = coordinates
        self.isBodyRegistered = isBodyRegistered
        self.isBodyAndPreferenceSort = isBodyAndPreferenceSort
        updateMoreFooter(hasMore: hasMore)
        collectionView.reloadData()

        // ボタンは登録/変更のみ（web の登録・変更ボタン相当）。
        measurementButton.setTitle(isBodyRegistered ? "変更" : "登録", for: .normal)
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
        statusLabel.text = "取得成功 count=\(coordinates.count) recType=\(recType.value) hasMore=\(hasMore) 登録済=\(isBodyRegistered)"

        // 表示できたら（1 件以上あるときのみ）Page View 計測を送信します（Android 版と同一）
        if !coordinates.isEmpty {
            coordinate.sendCoordinateViewEvent(recType: recType)
            // リストが画面内に 50% 以上・3 秒間表示されたら time=3000 の View 計測を自動送信します
            coordinate.startCoordinateViewTimeTracking(view: collectionView, recType: recType)
        }
    }

    /// beid（unisize と共有するユーザー識別子）が変わったときに呼ばれます。
    func aunnCoordinate(_ coordinate: AunnCoordinate, didChangeBeid beid: String) {
        // 検証用: unisize 非同居画面での CV 用に beid 変更を確認できます
        print("AunnTest > beid: \(beid)")
    }

    /// コーデ取得失敗時に呼ばれます。実アプリではコーデ一覧の枠ごと非表示にする想定です。
    func aunnCoordinate(_ coordinate: AunnCoordinate, didFail error: UnisizeError) {
        hideLoading()
        statusLabel.text = "エラー: \(error.errorCode.rawValue) \(error.errorCode.getMessage())"
    }
}

// MARK: - UICollectionView（コーデ一覧のネイティブ描画）

extension AunnCoordinateTestViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: AunnCoordinateGrid.cellReuseId,
            for: indexPath
        ) as! AunnCoordinateCell
        let item = items[indexPath.item]
        cell.configure(with: item)
        // 写真タップでコーデ詳細画面へ遷移します
        cell.onPhotoTapped = { [weak self] in
            self?.openCoordinateDetail(item)
        }
        // スタッフアイコンタップでスタッフ画面へ遷移します
        cell.onStaffIconTapped = { [weak self] in
            self?.openStaffDetail(item)
        }
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
        print("AunnTest > cell: コーデクリック計測 coordinateId=\(item.id) staffId=\(item.staff.id)")
        // クリック計測（経由履歴の記録も兼ねます）。コーデ詳細の View 計測は写真タップからの遷移先で送信します。
        coordinate.sendCoordinateLinkClickEvent(coordinateId: item.id, staffId: item.staff.id)
        statusLabel.text = "クリック計測: coordinate=\(item.id), staff=\(item.staff.id)"
    }
}

/// aunn コーデ詳細画面です（コーデ一覧の写真タップから遷移する検証用画面）。
/// 遷移元から渡された cid / coordinateId / imgUrl / staffId を表示し、表示完了時に
/// コーデ詳細の View 計測（page=coordination-detail）を 1 度だけ送信します。
final class AunnCoordinateDetailViewController: UIViewController {
    private let cid: String
    /// 遷移元の cuid をそのまま引き継ぎます。View 計測にも同じ値を載せないと、
    /// 一覧（コーデ取得）のログと cuid が食い違います。未入力なら nil のままにします。
    private let cuid: String?
    private let coordinateId: Int
    private let imgUrl: String
    private let staffId: Int
    private var hasSentTracking = false

    init(cid: String, cuid: String?, coordinateId: Int, imgUrl: String, staffId: Int) {
        self.cid = cid
        self.cuid = cuid
        self.coordinateId = coordinateId
        self.imgUrl = imgUrl
        self.staffId = staffId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "aunn コーデ詳細"
        view.backgroundColor = .systemBackground

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        SampleImageLoader.load(urlString: imgUrl, into: imageView)

        let infoLabel = UILabel()
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.numberOfLines = 0
        infoLabel.text = """
        cid: \(cid)
        cuid: \(cuid ?? "nil")
        coordinateId: \(coordinateId)
        staffId: \(staffId)
        imgUrl: \(imgUrl)
        """

        let stack = UIStackView(arrangedSubviews: [imageView, infoLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor,
                                              multiplier: 1.0 / AunnCoordinateGrid.imageAspectRatio),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 表示完了時にコーデ詳細の View 計測を送信します（戻る → 再表示での重複送信は抑止）
        guard !hasSentTracking else { return }
        hasSentTracking = true
        let tracking = AunnCoordinateTracking()
        tracking.setupParam(
            AunnCoordinateTracking.Param(
                cid: cid,
                pageType: .coordinationDetail,
                cuid: cuid,
                coordinateId: coordinateId,
                enablePrintLog: true
            )
        )
        tracking.send()
    }
}

/// aunn スタッフ画面です（コーデ一覧のスタッフアイコンタップから遷移する検証用画面）。
/// 遷移元から渡された cid / staffId / スタッフ写真を表示し、表示完了時に
/// スタッフの View 計測（page=staff）を 1 度だけ送信します。
final class AunnCoordinateStaffDetailViewController: UIViewController {
    private let cid: String
    /// 遷移元の cuid をそのまま引き継ぎます。View 計測にも同じ値を載せないと、
    /// 一覧（コーデ取得）のログと cuid が食い違います。未入力なら nil のままにします。
    private let cuid: String?
    private let staffId: Int
    private let staffImgUrl: String
    private var hasSentTracking = false

    init(cid: String, cuid: String?, staffId: Int, staffImgUrl: String) {
        self.cid = cid
        self.cuid = cuid
        self.staffId = staffId
        self.staffImgUrl = staffImgUrl
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "aunn スタッフ"
        view.backgroundColor = .systemBackground

        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .secondarySystemBackground
        SampleImageLoader.load(urlString: staffImgUrl, into: imageView)

        let infoLabel = UILabel()
        infoLabel.font = .systemFont(ofSize: 13)
        infoLabel.numberOfLines = 0
        infoLabel.text = """
        cid: \(cid)
        cuid: \(cuid ?? "nil")
        staffId: \(staffId)
        imgUrl: \(staffImgUrl)
        """

        let stack = UIStackView(arrangedSubviews: [imageView, infoLabel])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor,
                                              multiplier: 1.0 / AunnCoordinateGrid.imageAspectRatio),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 表示完了時にスタッフの View 計測を送信します（戻る → 再表示での重複送信は抑止）
        guard !hasSentTracking else { return }
        hasSentTracking = true
        let tracking = AunnCoordinateTracking()
        tracking.setupParam(
            AunnCoordinateTracking.Param(
                cid: cid,
                pageType: .staff,
                cuid: cuid,
                staffId: staffId,
                enablePrintLog: true
            )
        )
        tracking.send()
    }
}

/// コンテンツ全件ぶんの高さを自身の高さとして返す UICollectionView です。
/// 画面全体の UIScrollView にヘッダごと載せるため、isScrollEnabled = false で使用します。
private final class SelfSizingCollectionView: UICollectionView {
    override var contentSize: CGSize {
        didSet {
            if contentSize.height != oldValue.height {
                invalidateIntrinsicContentSize()
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: contentSize.height)
    }
}

/// 体型登録アプリ（AunnCoordinateMeasurement）を全画面表示する簡易コンテナです。
/// aunn 単独デモ・aunn + unisize 同居デモの双方から使用します。
final class AunnCoordinateMeasurementViewController: UIViewController {
    private let measurement = AunnCoordinateMeasurement()
    private let cid: String
    private let itemId: String?
    private let cuid: String?
    private let pageType: AunnCoordinatePageType
    var onCompleted: (() -> Void)?
    /// 完了・閉じる・スワイプダウンのどの経路でも、閉じ終わったときに 1 度だけ呼ばれます。
    var onDismissed: (() -> Void)?
    /// 体型登録アプリの読み込みに失敗したときに呼ばれます（呼び出し元のステータス表示用）。
    var onFailed: ((UnisizeError) -> Void)?

    // 読み込み失敗時だけ表示するエラー表示です。didFail はページを表示できなかったときに
    // 呼ばれ、WebView が白いままになるため、原因と閉じる導線を画面上にも出します。
    private let errorLabel = UILabel()
    private lazy var errorView: UIStackView = makeErrorView()

    init(cid: String, itemId: String?, cuid: String?, pageType: AunnCoordinatePageType) {
        self.cid = cid
        self.itemId = itemId
        self.cuid = cuid
        self.pageType = pageType
        super.init(nibName: nil, bundle: nil)
        // ネイティブの閉じるボタンを持たないため、シート表示にしてスワイプダウンを
        // 閉じる手段として残します（Web 側の continue purchase でも閉じられます）。
        modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *), let sheet = sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        measurement.delegate = self
        // スワイプダウンで閉じられたとき（dismissSelf を通らない経路）の後始末用です
        presentationController?.delegate = self

        let webView = measurement.view
        // SDK 側でも false に設定済みですが、制約で配置する View では明示しておくのが確実です
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        view.addSubview(errorView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),

            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        measurement.open(cid: cid, itemId: itemId, cuid: cuid, pageType: pageType, enablePrintLog: true)
    }

    /// 読み込み失敗時のエラー表示（初期は非表示）を組み立てます。
    private func makeErrorView() -> UIStackView {
        errorLabel.numberOfLines = 0
        errorLabel.textAlignment = .center
        errorLabel.font = .systemFont(ofSize: 13)

        let closeButton = UIButton(type: .system)
        closeButton.setTitle("閉じる", for: .normal)
        closeButton.addTarget(self, action: #selector(errorCloseTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [errorLabel, closeButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.isHidden = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }

    @objc private func errorCloseTapped() {
        dismissSelf()
    }

    private func dismissSelf() {
        measurement.close()
        dismiss(animated: true, completion: takeDismissHandler())
    }

    /// onDismissed を 1 度だけ実行できるよう取り出します。自身の解放後でも通知が届くよう、
    /// クロージャを取り出して完了ハンドラへ直接渡します。
    private func takeDismissHandler() -> (() -> Void)? {
        guard let handler = onDismissed else { return nil }
        onDismissed = nil
        return handler
    }
}

extension AunnCoordinateMeasurementViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        measurement.close()
        takeDismissHandler()?()
    }
}

extension AunnCoordinateMeasurementViewController: AunnCoordinateMeasurementDelegate {
    func aunnCoordinateMeasurementDidCompleteEnquete(_ measurement: AunnCoordinateMeasurement) {
        let completed = onCompleted
        dismissSelf()
        completed?()
    }

    func aunnCoordinateMeasurementDidClose(_ measurement: AunnCoordinateMeasurement) {
        dismissSelf()
    }

    /// 体型登録アプリを表示できなかったときに呼ばれます（cid 誤りや通信エラーなど）。
    /// WebView が白いままになるため、画面上にエラーと閉じる導線を出し、呼び出し元にも通知します。
    func aunnCoordinateMeasurement(_ measurement: AunnCoordinateMeasurement, didFail error: UnisizeError) {
        print("AunnCoordinateMeasurement error: \(error.errorCode.rawValue) \(error.errorCode.getMessage())")
        errorLabel.text = "体型登録アプリを開けませんでした\n\(error.errorCode.rawValue) \(error.errorCode.getMessage())"
        errorView.isHidden = false
        onFailed?(error)
    }
}
