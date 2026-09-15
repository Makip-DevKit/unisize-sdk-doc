package jp.co.makip.saas_unisize_sdk_android_kotlin_sample

import android.app.Dialog
import android.os.Bundle
import android.text.InputType
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.ScrollView
import android.widget.Switch
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import jp.co.makip.unisizesdk.UnisizeBanner
import jp.co.makip.unisizesdk.UnisizeBannerListener
import jp.co.makip.unisizesdk.UnisizeError
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinate
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateItem
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateListener
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateMeasurement
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateMeasurementListener
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinatePageType
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateParam
import jp.co.makip.unisizesdk.aunn.coordinate.AunnCoordinateRecommendAlgorithm

/**
 * aunn コーディネート SDK と unisize バナー SDK を **同一画面に同居** させた検証用画面です。
 *
 * 商品詳細ページを想定し、上部に unisize バナー（TEXT）、その下に aunn のコーディネート一覧を並べます。
 * beid は両 SDK で共有され（[jp.co.makip.unisizesdk.UnisizeBeidStore]）、体型登録の反映は
 * 「同一 beid で相手側を再ロード → サーバーが最新値を返す」ホスト駆動リロード方式で行います。
 *
 * - 順方向（#3）: aunn で体型登録完了 → [AunnCoordinateMeasurementListener.onEnqueteCompleted] で
 *   `coordinate.reload()` を呼び、aunn コーディネートを最新化します。unisize バナーは SDK が
 *   表示中の全バナーを再読込するため（`UnisizeBannerManager.refreshAll()`）、ホスト実装は不要です。
 * - 逆方向（#4）: unisize で体型登録/サイズレコメンド → [UnisizeBannerListener.didBeidChanged] で
 *   `coordinate.reload()` を呼び、aunn コーディネート（体型マッチ順・登録バナー表示）を最新化します。
 *   beid/属性はキャッシュ対象外のため reload() だけで鮮度が担保されます。
 *
 * cid / cuid / itemId は画面の入力欄から変更できます（既定値は [DEFAULT_CID] / [DEFAULT_ITEM_ID]）。
 * これらは aunn・unisize 双方で有効な値である必要があります。
 */
class AunnCoordinateWithUnisizeTestActivity : AppCompatActivity() {
    private lateinit var statusText: TextView
    private lateinit var cidInput: EditText
    private lateinit var cuidInput: EditText
    private lateinit var itemIdInput: EditText
    private lateinit var bannerContainer: LinearLayout
    private lateinit var listContainer: LinearLayout
    private lateinit var progressBar: ProgressBar
    private lateinit var measurementButton: Button
    private lateinit var bodyMatchingLabel: TextView
    private lateinit var bodyMatchingSwitch: Switch
    private lateinit var coordinate: AunnCoordinate
    private var unisizeBanner: UnisizeBanner? = null
    private var measurementDialog: Dialog? = null

    // 体型マッチ Switch をコードから更新する間はリスナー（再取得）を抑止するためのフラグです。
    private var suppressBodyMatchingListener = false

    companion object {
        private val TAG = AunnCoordinateWithUnisizeTestActivity::class.simpleName

        // 入力欄の既定値です。テストケースごとの切り替えは画面の入力欄で行うため、
        // 通常はここを書き換える必要はありません（aunn・unisize 双方で有効な値にしてください）。
        private const val DEFAULT_CID = ""
        private const val DEFAULT_ITEM_ID = ""
        private const val DEFAULT_COORDINATE_COUNT = 6

        /**
         * cuid 入力欄のヒントです。cuid は未入力を既定とし、入力されたときだけ送信します
         * （cuid を送ると体型推定が働き、レコメンドの種別が変わるためです）。
         */
        private const val CUID_HINT = "未入力なら送信しません"

        /** コーディネート一覧のグリッド列数です。 */
        private const val GRID_COLUMN_COUNT = 2
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(buildLayout())

        // 商品詳細ページ相当。unisize が beid を発行するため item-detail で解決します。
        coordinate =
            AunnCoordinate(this).apply {
                listener = coordinateListener
                setupParam(buildAunnParam())
            }

        // unisize バナーを表示します（体型登録の反映確認は didBeidChanged 経由）。
        buildUnisizeBanner().show()
    }

    override fun onDestroy() {
        // 測定アプリ表示中に Activity が破棄されると WindowLeaked になるため先に閉じます。
        // dismiss で OnDismissListener が走り、WebView の破棄まで行われます。
        measurementDialog?.dismiss()
        measurementDialog = null
        coordinate.stopCoordinateViewTimeTracking()
        unisizeBanner?.onDestroy()
        unisizeBanner = null
        super.onDestroy()
    }

    private fun buildLayout(): LinearLayout {
        val root =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setPadding(24, 24, 24, 24)
            }

        // 検証パラメータの入力欄です。テストケースごとの値をビルドし直さずに切り替えられるようにしています。
        // aunn へは「コーディネート取得 (load)」、unisize バナーへは「unisize バナー再表示」で反映します。
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

        statusText = TextView(this).apply { text = "aunn コーディネート + unisize 同居デモ" }
        root.addView(statusText)

        // コーディネート取得中に表示するプログレス（ホスト側で表示制御。SDK は開始/終了をコールバックで通知しない）。
        progressBar = ProgressBar(this).apply { visibility = View.GONE }
        root.addView(progressBar)

        // ▼ unisize バナー（同居）
        root.addView(TextView(this).apply { text = "▼ unisize バナー" })
        // 入力欄の変更をバナーへ反映するには作り直しが必要なため、差し替え先のコンテナを挟みます
        bannerContainer =
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                addView(buildUnisizeBanner())
            }
        root.addView(bannerContainer)
        root.addView(
            Button(this).apply {
                text = "unisize バナー再表示（入力反映）"
                setOnClickListener { rebuildUnisizeBanner() }
            },
        )

        // ▼ aunn 操作
        root.addView(
            Button(this).apply {
                text = "コーディネート取得 (load)"
                setOnClickListener {
                    requireCid() ?: return@setOnClickListener
                    // 入力欄の変更を毎回反映してから取得します
                    coordinate.setupParam(buildAunnParam())
                    statusText.text = "取得中..."
                    showLoading()
                    coordinate.load()
                }
            },
        )
        // 体型登録バナー相当の 1 行（web の登録バナー＋並べ替えチェックボックス相当）。コーディネート一覧の直上に置きます。
        // 左は並べ替えラベル＋体型マッチ ON/OFF トグル（登録済みのみ表示）、右は登録/変更ボタン。
        // 登録状況はコーディネート取得まで不明なため初期はラベル空・ボタン "-"、onCoordinatesLoaded で更新します。
        measurementButton =
            Button(this).apply {
                text = "-"
                setOnClickListener { openMeasurement() }
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
                addView(View(this@AunnCoordinateWithUnisizeTestActivity), LinearLayout.LayoutParams(0, 0, 1f))
                addView(measurementButton)
            },
        )

        val scroll =
            ScrollView(this).apply {
                layoutParams =
                    LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT,
                    )
            }
        listContainer = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
        scroll.addView(listContainer)
        root.addView(scroll)

        return root
    }

    /**
     * 入力欄の内容で aunn の起動パラメータを組み立てます。
     * この画面は商品詳細相当のため pageType は item-detail 固定で、itemId が必須です。
     * unisizeBeidWaitMs は同居する unisize バナーの beid 発行を待つ必要があるため既定値のままにします。
     */
    private fun buildAunnParam(): AunnCoordinateParam =
        AunnCoordinateParam(
            cid = inputCid(),
            cuid = inputCuid(),
            pageType = AunnCoordinatePageType.ITEM_DETAIL,
            coordinateCount = DEFAULT_COORDINATE_COUNT,
            itemId = inputItemId(),
            enablePrintLog = true,
        )

    /**
     * unisize バナーを入力欄の内容で作り直します。
     * バナーの cid / itemId は [UnisizeBanner.setupParam] で確定するため、値を変えるには
     * 作り直しが必要です。古いインスタンスは WebView を残さないよう `onDestroy()` で破棄します。
     */
    private fun rebuildUnisizeBanner() {
        requireCid() ?: return
        Log.d(TAG, "button: unisize バナー再表示 cid=${inputCid()} cuid=${inputCuid()} itemId=${inputItemId()}")
        unisizeBanner?.onDestroy()
        unisizeBanner = null
        bannerContainer.removeAllViews()
        bannerContainer.addView(buildUnisizeBanner())
        unisizeBanner?.show()
    }

    /**
     * aunn と同居させる unisize バナー（TEXT）を生成します。既存インスタンスがあれば再利用します。
     */
    private fun buildUnisizeBanner(): UnisizeBanner {
        unisizeBanner?.let { return it }
        val banner =
            UnisizeBanner(this).apply {
                layoutParams =
                    LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    )
                listener =
                    object : UnisizeBannerListener {
                        override fun didFinish() {
                            Log.d(TAG, "unisizeBanner > didFinish")
                        }

                        override fun didFail(unisizeError: UnisizeError) {
                            Log.d(TAG, "unisizeBanner > didFail: ${unisizeError.errMessage()}")
                            runOnUiThread {
                                layoutParams.height = 0
                                requestLayout()
                            }
                        }

                        override fun didResized(
                            width: Int,
                            height: Int,
                        ) {
                            runOnUiThread {
                                layoutParams.height = height
                                requestLayout()
                            }
                        }

                        override fun bannerClicked() {
                            Log.d(TAG, "unisizeBanner > bannerClicked")
                        }

                        override fun didUnsupported(message: String) {
                            Log.d(TAG, "unisizeBanner > didUnsupported: $message")
                            runOnUiThread {
                                layoutParams.height = 0
                                requestLayout()
                            }
                        }

                        override fun didBeidChanged(
                            beid: String,
                            recommendedItems: String,
                            type: String,
                        ) {
                            // 逆方向（#4）: unisize 側の体型登録/サイズレコメンドを aunn へ反映します。
                            Log.d(TAG, "unisizeBanner > didBeidChanged: beid=$beid type=$type → coordinate.reload()")
                            if (::coordinate.isInitialized) {
                                runOnUiThread {
                                    showLoading()
                                    coordinate.reload()
                                }
                            }
                        }
                    }
            }
        banner.setupParam(
            bannerType = UnisizeBanner.BannerType.TEXT,
            bannerMode = listOf(UnisizeBanner.BannerType.TEXT),
            itm = inputItemId(),
            cid = inputCid(),
            cuid = inputCuid().orEmpty(),
            lang = "",
            enableWebViewLog = true,
            enablePrintLog = true,
            sendErrorLog = true,
        )
        banner.addInterfaceToJavaScript(this)
        unisizeBanner = banner
        return banner
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
                    "取得成功: ${coordinates.size} 件 / recType=${recType.value} / " +
                        "登録=${if (isBodyRegistered) "済" else "未"}"
                renderCoordinates(coordinates, recType, hasMore)
            }

            override fun onBeidChanged(beid: String) {
                Log.d(TAG, "coordinate > onBeidChanged: $beid")
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
        // 2 カラムのグリッド表示（コーディネート画像付き）。セルの短タップで Click 計測を送信します。
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
        // 遷移先は未実装で、クリック計測の送信のみ行います。
        if (hasMore) {
            listContainer.addView(
                Button(this).apply {
                    text = "すべて見る"
                    setOnClickListener {
                        Log.d(TAG, "button: すべて見るクリック計測")
                        coordinate.sendMoreLinkClickEvent()
                        statusText.text = "クリック計測: すべて見る (more)"
                    }
                },
            )
        }
        if (coordinates.isNotEmpty()) {
            coordinate.sendCoordinateViewEvent(recType)
            // リストが画面内に 50% 以上・3 秒間表示されたら time=3000 の View 計測を自動送信します
            coordinate.startCoordinateViewTimeTracking(listContainer, recType)
        }
    }

    /**
     * コーディネート 1 件分のセル（コーディネート画像＋ラベル）を生成します。
     * 短タップで Click 計測、長押しで取得内容（レコメンド根拠の `v` を含む）の確認ダイアログを表示します。
     */
    private fun buildCoordinateCell(item: AunnCoordinateItem): View =
        LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(8, 8, 8, 8)
            addView(
                ImageView(this@AunnCoordinateWithUnisizeTestActivity).apply {
                    adjustViewBounds = true
                    contentDescription = "コーディネート #${item.id}"
                    layoutParams =
                        LinearLayout.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                        )
                    // レスポンスの imgUrl からコーディネート画像を取得して表示します
                    SampleImageLoader.load(item.imgUrl, this)
                },
            )
            addView(
                TextView(this@AunnCoordinateWithUnisizeTestActivity).apply {
                    text = "#${item.id} ${item.staff.name}"
                },
            )
            setOnClickListener {
                coordinate.sendCoordinateLinkClickEvent(item.id, item.staff.id)
                statusText.text = "クリック計測: coordinate=${item.id}, staff=${item.staff.id}"
            }
            setOnLongClickListener {
                AunnCoordinateItemDebugDialog.show(this@AunnCoordinateWithUnisizeTestActivity, TAG, item)
                true
            }
        }

    private fun openMeasurement() {
        val cid = requireCid() ?: return
        // 測定アプリ表示中は表示時間計測（time=3000）を止めます（Web 版の isOnEnquete 相当）
        coordinate.pauseCoordinateViewTimeTracking()
        val webView =
            AunnCoordinateMeasurement(this).apply {
                listener = measurementListener
                // この画面は商品詳細相当の固定構成のため、コーディネート取得（[buildAunnParam]）と
                // 同じく item-detail / itemId 入力値をそのまま渡します。
                open(
                    cid = cid,
                    itemId = inputItemId(),
                    cuid = inputCuid(),
                    pageType = AunnCoordinatePageType.ITEM_DETAIL,
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
                statusText.text = "体型登録完了 → aunn・unisize を再取得します"
                measurementDialog?.dismiss()
                measurementDialog = null
                // aunn コーディネートを再取得します（unisize バナーは SDK 側で再読込されます）
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
     * cid が空のまま送ると、コーディネート取得は SDK の onFail で気付けますが、体型登録アプリと
     * unisize バナーは空 cid のまま開いてしまい、画面上は無反応（または空表示）に見えます。
     * そのため送信前にここで弾きます。
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

    /** 入力欄の itemId です。この画面は item-detail 固定のため、未入力のときは既定値へ戻します。 */
    private fun inputItemId(): String {
        val value = itemIdInput.text.toString().trim()
        return value.ifEmpty { DEFAULT_ITEM_ID }
    }

    /** ラベルと入力欄を横並びにした 1 行を生成します。 */
    private fun buildLabeledInputRow(
        label: String,
        input: EditText,
    ): LinearLayout =
        LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            addView(TextView(this@AunnCoordinateWithUnisizeTestActivity).apply { text = label })
            addView(
                input,
                LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f),
            )
        }
}
