package jp.co.makip.saas_unisize_sdk_android_jetpack_sample

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue

class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            var showCvTagScreen by remember { mutableStateOf(false) }
            var showPurchaseWebViewScreen by remember { mutableStateOf(false) }
            var purchaseWebViewBeid by remember { mutableStateOf("") }
            var purchaseWebViewRecommendedItems by remember { mutableStateOf("") }

            when {
                showPurchaseWebViewScreen -> PurchaseWebViewComposeScreen(
                    beid = purchaseWebViewBeid,
                    recommendedItems = purchaseWebViewRecommendedItems,
                    onClose = { showPurchaseWebViewScreen = false },
                )
                showCvTagScreen -> CVTagComposeScreen(
                    onClose = { showCvTagScreen = false },
                )
                else -> UnisizeComposeScreen(
                    onNavigateToCvTagTest = { showCvTagScreen = true },
                    onNavigateToPurchaseWebView = { beid, recommendedItems ->
                        purchaseWebViewBeid = beid
                        purchaseWebViewRecommendedItems = recommendedItems
                        showPurchaseWebViewScreen = true
                    },
                )
            }
        }
    }
}
