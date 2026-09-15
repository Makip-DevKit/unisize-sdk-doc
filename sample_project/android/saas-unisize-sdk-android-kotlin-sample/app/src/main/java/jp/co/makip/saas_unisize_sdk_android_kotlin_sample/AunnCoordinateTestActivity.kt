package jp.co.makip.saas_unisize_sdk_android_kotlin_sample

import android.app.Dialog
import android.content.Context
import android.content.Intent
import android.graphics.Outline
import android.os.Bundle
import android.text.InputType
import android.text.TextUtils
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewOutlineProvider
import android.view.ViewGroup
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.Spinner
import android.widget.Switch
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import jp.co.makip.unisizesdk.UnisizeError
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinate
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateItem
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateListener
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateMeasurement
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateMeasurementListener
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinatePageType
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateParam
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateRecommendAlgorithm
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateTracking
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateTrackingParam

/**
 * aunn コーディネート SDK の検証用画面です。
 *
 * コーディネート一覧の取得（ネイティブ描画）→ 体型登録アプリ（WebView）→ 完了で再取得、
 * さらにコーディネート詳細相当の View 計測までを一画面で確認できます。
 * cid / cuid / itemId は画面の入力欄から変更できます（既定値は [DEFAULT_CID] / [DEFAULT_ITEM_ID]）。
 */
class AunnCoordinateTestActivity : AppCompatActivity() {
    private lateinit var statusText: TextView
    private lateinit var pageTypeSpinner: Spinner
    private lateinit var cidInput: EditText
    private lateinit var cuidInput: EditText
    private lateinit var itemIdInput: EditText
    private lateinit var coordinateCountInput: EditText
    private lateinit var coordinateIdInput: EditText
    private lateinit var staffIdInput: EditText
    private lateinit var listContainer: LinearLayout
    private lateinit var progressBar: ProgressBar
    private lateinit var measurementButton: Button
    private lateinit var bodyMatchingLabel: TextView
    private lateinit var bodyMatchingSwitch: Switch
    private lateinit var coordinate: AunnCoordinate
    private var measurementDialog: Dialog? = null
    private var selectedPageType: AunnCoordinatePageType = AunnCoordinatePageType.TOP

    // 体型マッチ Switch をコードから更新する間はリスナー（再取得）を抑止するためのフラグです。
    private var suppressBodyMatchingListener = false

    /** 「すべて見る」遷移で引き継いだ item_id です（itemId 不要の pageType でもトラッキングに含めます）。 */
    private var inheritedItemId: String? = null

    companion object {
        private val TAG = AunnCoordinateTestActivity::class.simpleName

        // 入力欄の既定値です。テストケースごとの切り替えは画面の入力欄で行うため、
        // 通常はここを書き換える必要はありません
        private const val DEFAULT_CID = ""
        private const val DEFAULT_ITEM_ID = ""
        private const val DEFAULT_COORDINATE_COUNT = 6

        /**
         * cuid 入力欄のヒントです。cuid は未入力を既定とし、入力されたときだけ送信します
         * （cuid を送ると体型推定が働き、レコメンドの種別が変わるためです）。
         */
        private const val CUID_HINT = "未入力なら送信しません"

        /**
         * 商品詳細ページで unisize バナーの beid 発行を待つ上限です。
         *
         * この画面は aunn コーディネート単独（unisize バナーを配置していない）ため、待っても beid は発行されません。
         * 既定の 3 秒のままだと商品詳細を選ぶたびにタイムアウト分だけ表示が遅れるので、待機を無効化します。
         * unisize と同居する画面（[AunnCoordinateWithUnisizeTestActivity]）では既定値のまま待たせる必要があります。
         */
        private const val UNISIZE_BEID_WAIT_MS = 0L

        /** コーディネート一覧のグリッド列数です。 */
        private const val GRID_COLUMN_COUNT = 2

        /** 写真下に表示する丸型スタッフアイコンの大きさ（dp）です。 */
        private const val STAFF_ICON_SIZE_DP = 40

        /** 「すべて見る」から開くコーディネート一覧の表示件数です。 */
        private const val MORE_LIST_COORDINATE_COUNT = 100

        private const val EXTRA_INITIAL_PAGE_TYPE = "initialPageType"
        private const val EXTRA_INITIAL_COORDINATE_COUNT = "initialCoordinateCount"
        private const val EXTRA_INITIAL_ITEM_ID = "initialItemId"
        private const val EXTRA_INITIAL_CID = "initialCid"
        private const val EXTRA_INITIAL_CUID = "initialCuid"

        /**
         * 「すべて見る」からの遷移用 Intent です。指定の pageType / 件数を初期表示して自動取得します。
         * 遷移先でも同じ条件で検証できるよう cid / cuid / itemId を引き継ぎ、入力欄に反映します
         * （beid は共有ストア経由で引き継がれます）。
         */
        fun createListIntent(
            context: Context,
            pageType: AunnCoordinatePageType,
            coordinateCount: Int,
            cid: String,
            cuid: String?,
            itemId: String?,
        ): Intent =
            Intent(context, AunnCoordinateTestActivity::class.java)
                .putExtra(EXTRA_INITIAL_PAGE_TYPE, pageType.name)
                .putExtra(EXTRA_INITIAL_COORDINATE_COUNT, coordinateCount)
                .putExtra(EXTRA_INITIAL_CID, cid)
                .putExtra(EXTRA_INITIAL_CUID, cuid)
                .putExtra(EXTRA_INITIAL_ITEM_ID, itemId)

        /** コーディネート取得（表示タグ）向けの pageType と表示文言です。 */
        private val DISPLAY_PAGE_TYPES =
            listOf(
                AunnCoordinatePageType.TOP to "トップページ",
                AunnCoordinatePageType.COORDINATE to "コーディネート一覧（トップ経由）",
                AunnCoordinatePageType.COORDINATE_ITEM to "コーディネート一覧（商品詳細経由）",
                AunnCoordinatePageType.ITEM_DETAIL to "商品詳細ページ",
            )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildLayout())

        coordinate =
            AunnCoordinate(this).apply {
                listener = coordinateListener
                setupParam(
                    AunnCoordinateParam(
                        cid = inputCid(),
                        cuid = inputCuid(),
                        pageType = AunnCoordinatePageType.TOP,
                        coordinateCount = DEFAULT_COORDINATE_COUNT,
                        unisizeBeidWaitMs = UNISIZE_BEID_WAIT_MS,
                        enablePrintLog = true,
                    ),
                )
            }

        // 「すべて見る」からの遷移時は、指定の pageType / 件数を初期表示して自動取得します。
        // 遷移元の cid / cuid / itemId を入力欄へ復元し、同じ条件のまま検証を続けられるようにします
        // （beid は共有ストア経由で引き継がれます）。
        val initialPageTypeName = intent.getStringExtra(EXTRA_INITIAL_PAGE_TYPE)
        if (initialPageTypeName != null) {
            val pageType = AunnCoordinatePageType.valueOf(initialPageTypeName)
            val count = intent.getIntExtra(EXTRA_INITIAL_COORDINATE_COUNT, DEFAULT_COORDINATE_COUNT)
            selectedPageType = pageType
            inheritedItemId = intent.getStringExtra(EXTRA_INITIAL_ITEM_ID)
            intent.getStringExtra(EXTRA_INITIAL_CID)?.let { cidInput.setText(it) }
            // cuid は未指定（null）と空文字を区別せず、どちらも「送信しない」として空欄にします
            cuidInput.setText(intent.getStringExtra(EXTRA_INITIAL_CUID).orEmpty())
            inheritedItemId?.let { itemIdInput.setText(it) }
            DISPLAY_PAGE_TYPES.indexOfFirst { it.first == pageType }
                .takeIf { it >= 0 }
                ?.let { pageTypeSpinner.setSelection(it) }
            coordinateCountInput.setText(count.toString())
            val cid = requireCid()
            if (cid != null) {
                statusText.text = "取得中..."
                coordinate.setupParam(
                    AunnCoordinateParam(
                        cid = cid,
                        cuid = inputCuid(),
                        pageType = pageType,
                        coordinateCount = count,
                        itemId = effectiveItemId(),
                        unisizeBeidWaitMs = UNISIZE_BEID_WAIT_MS,
                        enablePrintLog = true,
                    ),
                )
                showLoading()
                coordinate.load()
            }
        }
    }

    override fun onDestroy() {
        // 測定アプリ表示中に Activity が破棄されると WindowLeaked になるため先に閉じます。
        // dismiss で OnDismissListener が走り、WebView の破棄まで行われます。
        measurementDialog?.dismiss()
        measurementDialog = null
        super.onDestroy()
    }

    private fun buildLayout(): View {
        val root =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(24, 24, 24, 24)
            }

        // 検証パラメータの入力欄です。テストケースごとの値をビルドし直さずに切り替えられるようにしています。
        cidInput =
            EditText(this).apply {
                setText(DEFAULT_CID)
                inputType = InputType.TYPE_CLASS_TEXT
            }
        root.addView(buildLabeledInputRow("cid：", cidInput))

        cuidInput =
            EditText(this).apply {
                hint = CUID_HINT
                inputType = InputType.TYPE_CLASS_TEXT
            }
        root.addView(buildLabeledInputRow("cuid：", cuidInput))

        itemIdInput =
            EditText(this).apply {
                setText(DEFAULT_ITEM_ID)
                inputType = InputType.TYPE_CLASS_TEXT
            }
        root.addView(buildLabeledInputRow("itemId：", itemIdInput))

        statusText = TextView(this).apply { text = "「コーディネート取得」を押してください" }
        root.addView(statusText)

        // コーディネート取得中に表示するプログレス（ホスト側で表示制御。SDK は開始/終了をコールバックで通知しない）。
        progressBar = ProgressBar(this).apply { visibility = View.GONE }
        root.addView(progressBar)

        root.addView(TextView(this).apply { text = "pageType" })
        pageTypeSpinner =
            Spinner(this).apply {
                adapter =
                    ArrayAdapter(
                        this@AunnCoordinateTestActivity,
                        android.R.layout.simple_spinner_dropdown_item,
                        DISPLAY_PAGE_TYPES.map { it.second },
                    )
                onItemSelectedListener =
                    object : AdapterView.OnItemSelectedListener {
                        override fun onItemSelected(
                            parent: AdapterView<*>?,
                            view: View?,
                            position: Int,
                            id: Long,
                        ) {
                            selectedPageType = DISPLAY_PAGE_TYPES[position].first
                        }

                        override fun onNothingSelected(parent: AdapterView<*>?) = Unit
                    }
            }
        root.addView(pageTypeSpinner)

        root.addView(TextView(this).apply { text = "coordinateCount" })
        coordinateCountInput =
            EditText(this).apply {
                setText(DEFAULT_COORDINATE_COUNT.toString())
                inputType = InputType.TYPE_CLASS_NUMBER
            }
        root.addView(coordinateCountInput)

        root.addView(
            Button(this).apply {
                text = "コーディネート取得 (load)"
                setOnClickListener {
                    val cid = requireCid() ?: return@setOnClickListener
                    val count = coordinateCountInput.text.toString().toIntOrNull()
                    if (count == null || count <= 0) {
                        statusText.text = "coordinateCount は 1 以上の整数を指定してください"
                        return@setOnClickListener
                    }
                    val itemId = effectiveItemId()
                    Log.d(
                        TAG,
                        "button: コーディネート取得 (load) cid=$cid cuid=${inputCuid()} itemId=$itemId " +
                            "pageType=${selectedPageType.value} coordinateCount=$count",
                    )
                    statusText.text = "取得中..."
                    coordinate.setupParam(
                        AunnCoordinateParam(
                            cid = cid,
                            cuid = inputCuid(),
                            pageType = selectedPageType,
                            coordinateCount = count,
                            itemId = itemId,
                            unisizeBeidWaitMs = UNISIZE_BEID_WAIT_MS,
                            enablePrintLog = true,
                        ),
                    )
                    showLoading()
                    coordinate.load()
                }
            },
        )

        coordinateIdInput =
            EditText(this).apply {
                hint = "例: 12345"
                inputType = InputType.TYPE_CLASS_NUMBER
            }
        root.addView(buildLabeledInputRow("coordinateId：", coordinateIdInput))
        root.addView(
            Button(this).apply {
                text = "コーディネート詳細 View 計測 (coordination-detail)"
                setOnClickListener {
                    val coordinateId = coordinateIdInput.text.toString().toIntOrNull()
                    if (coordinateId == null) {
                        statusText.text = "coordinateId は整数で指定してください"
                        return@setOnClickListener
                    }
                    Log.d(TAG, "button: コーディネート詳細 View 計測 coordinateId=$coordinateId")
                    sendDetailView(AunnCoordinatePageType.COORDINATE_DETAIL, coordinateId = coordinateId, staffId = null)
                }
            },
        )

        staffIdInput =
            EditText(this).apply {
                hint = "例: 678"
                inputType = InputType.TYPE_CLASS_NUMBER
            }
        root.addView(buildLabeledInputRow("staffId：", staffIdInput))
        root.addView(
            Button(this).apply {
                text = "スタッフ詳細 View 計測 (staff)"
                setOnClickListener {
                    val staffId = staffIdInput.text.toString().toIntOrNull()
                    if (staffId == null) {
                        statusText.text = "staffId は整数で指定してください"
                        return@setOnClickListener
                    }
                    Log.d(TAG, "button: スタッフ詳細 View 計測 staffId=$staffId")
                    sendDetailView(AunnCoordinatePageType.STAFF, coordinateId = null, staffId = staffId)
                }
            },
        )

        // 体型登録バナー相当の 1 行（web の登録バナー＋並べ替えチェックボックス相当）。コーディネート一覧の直上に置きます。
        // 左は並べ替えラベル＋体型マッチ ON/OFF トグル（登録済みのみ表示）、右は登録/変更ボタン。
        // 登録状況はコーディネート取得まで不明なため初期はラベル空・ボタン "-"、onCoordinatesLoaded で更新します。
        measurementButton =
            Button(this).apply {
                text = "-"
                setOnClickListener {
                    // オープン計測は AunnCoordinateMeasurement が自動送信します
                    Log.d(TAG, "button: $text cid=${inputCid()} cuid=${inputCuid()} itemId=${inputItemId()}")
                    openMeasurement()
                }
            }
        bodyMatchingLabel =
            TextView(this).apply {
                // 背景色（#f0f0f0）は端末のダークテーマでも固定のため、文字色も濃色で固定します
                setTextColor(0xFF333333.toInt())
            }
        bodyMatchingSwitch =
            Switch(this).apply {
                visibility = View.GONE
                setOnCheckedChangeListener { _, isChecked ->
                    if (suppressBodyMatchingListener) return@setOnCheckedChangeListener
                    Log.d(TAG, "switch: toggleBodyMatching=$isChecked")
                    coordinate.toggleBodyMatching(isChecked)
                    statusText.text = "体型マッチ切替: $isChecked → 再取得します"
                    showLoading()
                    coordinate.reload()
                }
            }
        root.addView(
            LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setBackgroundColor(0xFFF0F0F0.toInt())
                setPadding(16, 8, 16, 8)
                addView(bodyMatchingLabel)
                addView(bodyMatchingSwitch)
                addView(View(this@AunnCoordinateTestActivity), LinearLayout.LayoutParams(0, 0, 1f))
                addView(measurementButton)
            },
        )

        // リストは全件をそのまま並べ、リスト単体ではスクロールさせません。
        // ヘッダも固定せず、画面全体を 1 つのスクロールとしてまとめます。
        listContainer = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        root.addView(listContainer)

        return ScrollView(this).apply { addView(root) }
    }

    /** ラベルと入力欄を「ラベル：入力欄」の横並び 1 行にまとめた行を生成します。 */
    private fun buildLabeledInputRow(
        label: String,
        input: EditText,
    ): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(TextView(this@AunnCoordinateTestActivity).apply { text = label })
            addView(
                input,
                LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f),
            )
        }

    private val coordinateListener =
        object : AunnCoordinateListener {
            override fun onCoordinatesLoaded(
                coordinates: List<AunnCoordinateItem>,
                recType: AunnCoordinateRecommendAlgorithm,
                hasMore: Boolean,
                isBodyRegistered: Boolean,
                isBodyAndPreferenceSort: Boolean,
            ) {
                hideLoading()
                // ボタンは登録/変更のみ（web の登録・変更ボタン相当）。
                measurementButton.text = if (isBodyRegistered) "変更" else "登録"
                // 体型マッチのトグルは登録済みのときだけ表示。登録済みのラベルは体型×協調かで出し分け（web と同一）。
                if (isBodyRegistered) {
                    bodyMatchingLabel.text =
                        if (isBodyAndPreferenceSort) "体型と好みで並べ替え" else "体型で並べ替え"
                    suppressBodyMatchingListener = true
                    bodyMatchingSwitch.isChecked = coordinate.useBodyMatching
                    suppressBodyMatchingListener = false
                    bodyMatchingSwitch.visibility = View.VISIBLE
                } else {
                    bodyMatchingLabel.text = "あなたの体型で並べ替え"
                    bodyMatchingSwitch.visibility = View.GONE
                }
                statusText.text =
                    "取得成功: ${coordinates.size} 件 / recType=${recType.value} / hasMore=$hasMore / " +
                        "登録=${if (isBodyRegistered) "済" else "未"}"
                renderCoordinates(coordinates, recType, hasMore)
            }

            override fun onBeidChanged(beid: String) {
                // 検証用: unisize 非同居画面での CV 用に beid 変更を確認できます
                Log.d(TAG, "onBeidChanged: $beid")
            }

            override fun onFail(error: UnisizeError) {
                hideLoading()
                statusText.text = "エラー: ${error.errMessage()} (${error.errCode()})"
            }
        }

    private fun renderCoordinates(
        coordinates: List<AunnCoordinateItem>,
        recType: AunnCoordinateRecommendAlgorithm,
        hasMore: Boolean,
    ) {
        listContainer.removeAllViews()
        // ホストアプリがネイティブ描画する例（2 カラムのグリッド表示・コーディネート画像付き）。
        // 全件を自然なサイズで並べます（スクロールは画面全体の ScrollView が担います）。
        // 短タップ = Click 計測、長押し = API 取得データの詳細確認（ダイアログ + Logcat ダンプ）。
        coordinates.chunked(GRID_COLUMN_COUNT).forEach { rowItems ->
            val row =
                LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    layoutParams =
                        LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                        )
                }
            rowItems.forEach { item ->
                row.addView(
                    buildCoordinateCell(item),
                    LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f),
                )
            }
            // 端数の行は空セルで埋めて列幅を揃えます
            repeat(GRID_COLUMN_COUNT - rowItems.size) {
                row.addView(View(this), LinearLayout.LayoutParams(0, 0, 1f))
            }
            listContainer.addView(row)
        }
        // hasMore のときだけリスト末尾に「すべて見る」を表示します（web の more リンク相当）。
        if (hasMore) {
            listContainer.addView(
                Button(this).apply {
                    text = "すべて見る"
                    setOnClickListener {
                        // 新しい aunn テスト画面をコーディネート一覧・100 件で開きます。
                        // 商品詳細（item-detail）からの遷移は一覧（商品）タブ（coordination-item）、それ以外はコーディネート一覧タブです。
                        // item_id 付きの画面からの遷移では、遷移先のコーディネート一覧のトラッキングへ item_id を引き継ぎます。
                        val destinationPageType =
                            if (selectedPageType == AunnCoordinatePageType.ITEM_DETAIL) {
                                AunnCoordinatePageType.COORDINATE_ITEM
                            } else {
                                AunnCoordinatePageType.COORDINATE
                            }
                        Log.d(
                            TAG,
                            "button: すべて見るクリック計測 → ${destinationPageType.value}" +
                                "（$MORE_LIST_COORDINATE_COUNT 件）を新規画面で表示",
                        )
                        coordinate.sendMoreLinkClickEvent()
                        statusText.text = "クリック計測: すべて見る (more)"
                        val cid = requireCid() ?: return@setOnClickListener
                        startActivity(
                            createListIntent(
                                this@AunnCoordinateTestActivity,
                                destinationPageType,
                                MORE_LIST_COORDINATE_COUNT,
                                cid,
                                inputCuid(),
                                effectiveItemId(),
                            ),
                        )
                    }
                },
            )
        }
        // 取得後にビューイベントを送信します
        if (coordinates.isNotEmpty()) {
            coordinate.sendCoordinateViewEvent(recType)
            // リストが画面内に 50% 以上・3 秒間表示されたら time=3000 の View 計測を自動送信します
            coordinate.startCoordinateViewTimeTracking(listContainer, recType)
        }
    }

    /**
     * コーディネート 1 件分のセル（コーディネート画像＋スタッフ情報行）を生成します。
     * セル全体をタップ領域とし、短タップで Click 計測、長押しで詳細ダイアログを表示します。
     */
    private fun buildCoordinateCell(item: AunnCoordinateItem): View =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(8, 8, 8, 8)
            addView(
                ImageView(this@AunnCoordinateTestActivity).apply {
                    adjustViewBounds = true
                    contentDescription = "コーディネート #${item.id}"
                    layoutParams =
                        LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                        )
                    // レスポンスの imgUrl からコーディネート画像を取得して表示します
                    SampleImageLoader.load(item.imgUrl, this)
                    // 写真タップでコーディネート詳細画面へ遷移します（詳細 View 計測は遷移先の表示完了時に送信）
                    setOnClickListener {
                        val cid = requireCid() ?: return@setOnClickListener
                        Log.d(TAG, "cell: コーディネート写真タップ coordinateId=${item.id} staffId=${item.staff.id} → 詳細画面へ")
                        // クリック計測（経由履歴の記録も兼ねます）
                        coordinate.sendCoordinateLinkClickEvent(item.id, item.staff.id)
                        startActivity(
                            AunnCoordinateDetailActivity.createIntent(
                                this@AunnCoordinateTestActivity,
                                cid,
                                inputCuid(),
                                item.id,
                                item.imgUrl,
                                item.staff.id,
                            ),
                        )
                    }
                    // 写真はクリック可能でタッチを消費するため、親セルの長押しが届きません。
                    // 写真からも取得内容の確認ダイアログを開けるよう、ここでも長押しを受けます。
                    setOnLongClickListener {
                        showCoordinateDetail(item)
                        true
                    }
                },
            )
            addView(buildStaffInfoRow(item))
            setOnClickListener {
                Log.d(
                    TAG,
                    "cell: コーディネートクリック計測 coordinateId=${item.id} staffId=${item.staff.id}",
                )
                coordinate.sendCoordinateLinkClickEvent(item.id, item.staff.id)
                statusText.text = "クリック計測: coordinate=${item.id}, staff=${item.staff.id}"
            }
            setOnLongClickListener {
                showCoordinateDetail(item)
                true
            }
        }

    /**
     * 写真下のスタッフ情報行を生成します。
     * 左に丸型のスタッフアイコン、右にショップ名／スタッフ名+身長／bodyType+personalColor の 3 行を表示します。
     */
    private fun buildStaffInfoRow(item: AunnCoordinateItem): View {
        val iconSize = (STAFF_ICON_SIZE_DP * resources.displayMetrics.density).toInt()
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, 8, 0, 0)
            addView(
                ImageView(this@AunnCoordinateTestActivity).apply {
                    scaleType = ImageView.ScaleType.CENTER_CROP
                    contentDescription = "スタッフ #${item.staff.id}"
                    setBackgroundColor(0xFFEEEEEE.toInt())
                    // スタッフアイコンは丸くクリップして表示します
                    outlineProvider =
                        object : ViewOutlineProvider() {
                            override fun getOutline(
                                view: View,
                                outline: Outline,
                            ) {
                                outline.setOval(0, 0, view.width, view.height)
                            }
                        }
                    clipToOutline = true
                    SampleImageLoader.load(item.staff.imgUrl, this)
                    // アイコンタップでスタッフ画面へ遷移します（スタッフの View 計測は遷移先の表示完了時に送信）
                    setOnClickListener {
                        val cid = requireCid() ?: return@setOnClickListener
                        Log.d(TAG, "cell: スタッフアイコンタップ staffId=${item.staff.id} → スタッフ画面へ")
                        // クリック計測（経由履歴の記録も兼ねます。スタッフ画面の計測は staffId で照合されます）
                        coordinate.sendCoordinateLinkClickEvent(item.id, item.staff.id)
                        startActivity(
                            AunnStaffDetailActivity.createIntent(
                                this@AunnCoordinateTestActivity,
                                cid,
                                inputCuid(),
                                item.staff.id,
                                item.staff.imgUrl,
                            ),
                        )
                    }
                    // 写真と同じ理由で、アイコン上の長押しもここで受けます。
                    setOnLongClickListener {
                        showCoordinateDetail(item)
                        true
                    }
                },
                LinearLayout.LayoutParams(iconSize, iconSize),
            )
            addView(
                LinearLayout(this@AunnCoordinateTestActivity).apply {
                    orientation = LinearLayout.VERTICAL
                    setPadding(12, 0, 0, 0)
                    addView(buildStaffInfoText(item.shop.name))
                    addView(buildStaffInfoText("${displayStaffName(item.staff.name)} ${item.staff.height}cm"))
                    addView(
                        buildStaffInfoText(
                            listOfNotNull(item.staff.bodyType, item.staff.personalColor).joinToString(" / "),
                        ),
                    )
                },
                LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f),
            )
        }
    }

    private fun buildStaffInfoText(value: String): TextView =
        TextView(this).apply {
            text = value
            textSize = 11f
            maxLines = 1
            ellipsize = TextUtils.TruncateAt.END
        }

    /** スタッフ名の【...】部分（注記）を除いた表示用の名前を返します。 */
    private fun displayStaffName(name: String): String = name.replace(Regex("【.*?】"), "").trim()

    /**
     * 長押しで、API から取得したコーディネート 1 件の全項目（レコメンド根拠の `v` を含む）を
     * ダイアログ表示し、Logcat にも全ダンプします。短タップの Click 計測とは役割を分けています。
     */
    private fun showCoordinateDetail(item: AunnCoordinateItem) {
        AunnCoordinateItemDebugDialog.show(this, TAG, item)
    }

    private fun openMeasurement() {
        val cid = requireCid() ?: return
        // 測定アプリ表示中は表示時間計測（time=3000）を止めます（Web 版の isOnEnquete 相当）
        coordinate.pauseCoordinateViewTimeTracking()
        val webView =
            AunnCoordinateMeasurement(this).apply {
                listener = measurementListener
                // pageType / itemId はコーディネート取得と同じ値を渡します。体型登録バナーの
                // click / complete 計測にそのまま載るため、ここがずれるとコーディネート取得側のログと
                // page・item_id が食い違います。
                open(
                    cid = cid,
                    itemId = effectiveItemId(),
                    cuid = inputCuid(),
                    pageType = selectedPageType,
                    enablePrintLog = true,
                )
            }
        measurementDialog =
            Dialog(this, android.R.style.Theme_Black_NoTitleBar_Fullscreen).apply {
                setContentView(webView)
                // 完了・「購入を続ける」・バックキーのどの経路でも、ダイアログが消えたら
                // 表示時間計測を再開し、WebView を破棄します（破棄しないとネイティブ側の
                // WebView が GC まで動き続け、連続で開くとインスタンスが累積します）
                setOnDismissListener {
                    coordinate.resumeCoordinateViewTimeTracking()
                    webView.onDestroy()
                    measurementDialog = null
                }
                show()
            }
    }

    private val measurementListener =
        object : AunnCoordinateMeasurementListener {
            override fun onEnqueteCompleted() {
                statusText.text = "体型登録完了 → 再取得します"
                measurementDialog?.dismiss()
                measurementDialog = null
                showLoading()
                coordinate.reload()
            }

            override fun onClosed() {
                measurementDialog?.dismiss()
                measurementDialog = null
            }

            override fun onFail(error: UnisizeError) {
                statusText.text = "測定アプリエラー: ${error.errMessage()}"
            }
        }

    private fun sendDetailView(
        pageType: AunnCoordinatePageType,
        coordinateId: Int?,
        staffId: Int?,
    ) {
        val cid = requireCid() ?: return
        AunnCoordinateTracking(this).apply {
            setupParam(
                AunnCoordinateTrackingParam(
                    cid = cid,
                    pageType = pageType,
                    cuid = inputCuid(),
                    coordinateId = coordinateId,
                    staffId = staffId,
                    enablePrintLog = true,
                ),
            )
            send()
        }
        statusText.text =
            "${pageType.value} View ログを送信しました (coordinateId=$coordinateId, staffId=$staffId)"
    }

    /** コーディネート取得（load/reload）の直前に呼びます。終了は onCoordinatesLoaded / onFail で [hideLoading]。 */
    private fun showLoading() {
        progressBar.visibility = View.VISIBLE
    }

    private fun hideLoading() {
        progressBar.visibility = View.GONE
    }

    /** 入力欄の cid です（前後の空白は除きます）。未入力のときは空文字を返します。 */
    private fun inputCid(): String = cidInput.text.toString().trim()

    /**
     * 入力欄の cid を必須として取り出します。未入力ならエラーを表示して null を返します。
     *
     * cid が空のまま送ると、コーディネート取得は SDK の onFail で気付けますが、View 計測（[AunnCoordinateTracking]）は
     * SDK 内部で例外を握り潰して Logcat に出すだけ、体型登録アプリは空 cid のまま開いてしまい、
     * どちらも画面上は無反応に見えます。そのため送信前にここで弾きます。
     */
    private fun requireCid(): String? {
        val value = inputCid()
        if (value.isEmpty()) {
            statusText.text = "cid を入力してください"
            return null
        }
        return value
    }

    /** 入力欄の cuid です。未入力のときは送信しません。 */
    private fun inputCuid(): String? {
        val value = cuidInput.text.toString().trim()
        return value.ifEmpty { null }
    }

    /** 入力欄の itemId です。未入力のときは送信しません。 */
    private fun inputItemId(): String? {
        val value = itemIdInput.text.toString().trim()
        return value.ifEmpty { null }
    }

    /**
     * 現在の pageType で送信する itemId です。itemId 必須の pageType は入力欄の値、
     * それ以外は「すべて見る」遷移で引き継いだ item_id（なければ null）を使います。
     */
    private fun effectiveItemId(): String? = if (selectedPageType.requiresItemId()) inputItemId() else inheritedItemId
}
