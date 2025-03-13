package jp.co.makip.saas_unisize_sdk_android_java_sample;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import java.util.List;
import java.util.stream.Collectors;
import java.util.Arrays;

import jp.co.makip.unisizesdk.UnisizeBanner;
import jp.co.makip.unisizesdk.UnisizeBannerListener;
import jp.co.makip.unisizesdk.UnisizeError;

public class UnisizeFragment extends Fragment {

    private UnisizeBanner textWebView;
    private UnisizeBanner exWebView;
    private UnisizeBanner ciWebView;

    private String cid = "";
    private String itm = "";
    private String cuid = "";
    private String lang = "";

    private String customStyle = "";

    private List<UnisizeBanner.BannerType> sdkBnrMode = Arrays.asList(
            UnisizeBanner.BannerType.TEXT,
            UnisizeBanner.BannerType.EX
    );

    public UnisizeFragment() {
        super(R.layout.fragment_unisize);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        textWebView = view.findViewById(R.id.textWebView);
        exWebView = view.findViewById(R.id.exWebView);
        ciWebView = view.findViewById(R.id.ciWebView);

        setupTextWebView();
        setupCiWebView();
        setupButtons(view);
    }

    private void setupTextWebView() {
        textWebView.setListener(new UnisizeBannerListener() {
            @Override
            public void didFinish() {
                Log.d("MainActivity", "textWebView didFinish()");
                setupExWebView();
            }

            @Override
            public void didFail(UnisizeError unisizeError) {
                String message = unisizeError.errMessage();
                Log.d("MainActivity", "textWebView didFail(" + message + ")");
                getActivity().runOnUiThread(() -> {
                    textWebView.getLayoutParams().height = 0;
                    textWebView.requestLayout();
                });
            }

            @Override
            public void didResized(int width, int height) {
                Log.d("MainActivity", "textWebView didResized(width：" + width + "、height：" + height + ")");
                getActivity().runOnUiThread(() -> {
                    textWebView.getLayoutParams().height = height;
                    textWebView.requestLayout();
                });
            }

            @Override
            public void bannerClicked() {
                Log.d("MainActivity", "textWebView bannerClicked()");
            }

            @Override
            public void didUnsupported(String message) {
                Log.d("MainActivity", "textWebView didUnsupported(" + message + ")");
                getActivity().runOnUiThread(() -> {
                    textWebView.getLayoutParams().height = 0;
                    textWebView.requestLayout();
                });
            }

            @Override
            public void didBeidChanged(String beid, String recommendedItems, String type) {
                Log.d("MainActivity", "textWebView didBeidChanged(beid: " + beid + ", recommendedItems: " + recommendedItems + ")");
            }
        });

        textWebView.setupParam(
                UnisizeBanner.BannerType.TEXT,
                sdkBnrMode,
                itm,
                cid,
                cuid,
                lang,
                true,
                true,
                true,
                customStyle
        );

        textWebView.addInterfaceToJavaScript(requireContext());
        textWebView.show();
    }

    private void setupExWebView() {
        if (exWebView != null) {
            exWebView.setListener(new UnisizeBannerListener() {
                @Override
                public void didFinish() {
                    Log.d("MainActivity", "exWebView didFinish()");
                }

                @Override
                public void didFail(UnisizeError unisizeError) {
                    String message = unisizeError.errMessage();
                    Log.d("MainActivity", "exWebView didFail(" + message + ")");
                    getActivity().runOnUiThread(() -> {
                        exWebView.getLayoutParams().height = 0;
                        exWebView.requestLayout();
                    });
                }

                @Override
                public void didResized(int width, int height) {
                    Log.d("MainActivity", "exWebView didResized(width：" + width + "、height：" + height + ")");
                    getActivity().runOnUiThread(() -> {
                        exWebView.getLayoutParams().height = height;
                        exWebView.requestLayout();
                    });
                }

                @Override
                public void bannerClicked() {
                    Log.d("MainActivity", "exWebView bannerClicked()");
                }

                @Override
                public void didUnsupported(String message) {
                    Log.d("MainActivity", "exWebView didUnsupported(" + message + ")");
                    getActivity().runOnUiThread(() -> {
                        exWebView.getLayoutParams().height = 0;
                        exWebView.requestLayout();
                    });
                }

                @Override
                public void didBeidChanged(String beid, String recommendedItems, String type) {
                    Log.d("MainActivity", "exWebView didBeidChanged(beid: " + beid + ", recommendedItems: " + recommendedItems + ")");
                }
            });

            exWebView.setupParam(
                    UnisizeBanner.BannerType.EX,
                    sdkBnrMode,
                    itm,
                    cid,
                    cuid,
                    lang,
                    true,
                    true,
                    true,
                    customStyle
            );

            exWebView.addInterfaceToJavaScript(requireContext());
            exWebView.show();
        }
    }

    private void setupCiWebView() {
        if (ciWebView != null) {
            ciWebView.setListener(new UnisizeBannerListener() {
                @Override
                public void didFinish() {
                    Log.d("MainActivity", "ciWebView didFinish()");
                }

                @Override
                public void didFail(UnisizeError unisizeError) {
                    String message = unisizeError.errMessage();
                    Log.d("MainActivity", "ciWebView didFail(" + message + ")");
                    getActivity().runOnUiThread(() -> {
                        ciWebView.getLayoutParams().height = 0;
                        ciWebView.requestLayout();
                    });
                }

                @Override
                public void didResized(int width, int height) {
                    Log.d("MainActivity", "ciWebView didResized(width：" + width + "、height：" + height + ")");
                    getActivity().runOnUiThread(() -> {
                        ciWebView.getLayoutParams().height = height;
                        ciWebView.requestLayout();
                    });
                }

                @Override
                public void bannerClicked() {
                    Log.d("MainActivity", "ciWebView bannerClicked()");
                }

                @Override
                public void didUnsupported(String message) {
                    Log.d("MainActivity", "ciWebView didUnsupported(" + message + ")");
                    getActivity().runOnUiThread(() -> {
                        ciWebView.getLayoutParams().height = 0;
                        ciWebView.requestLayout();
                    });
                }

                @Override
                public void didBeidChanged(String beid, String recommendedItems, String type) {
                    Log.d("MainActivity", "ciWebView didBeidChanged(beid: " + beid + ", recommendedItems: " + recommendedItems + ")");
                }
            });

            ciWebView.setupParam(
                    UnisizeBanner.BannerType.CI,
                    sdkBnrMode,
                    itm,
                    cid,
                    cuid,
                    lang,
                    true,
                    true,
                    true,
                    customStyle
            );

            ciWebView.addInterfaceToJavaScript(requireContext());
            ciWebView.show();
        }
    }

    private void setupButtons(View view) {
        EditText itmEdit = view.findViewById(R.id.itm);
        EditText cidEdit = view.findViewById(R.id.cid);
        EditText cuidEdit = view.findViewById(R.id.cuid);
        EditText langEdit = view.findViewById(R.id.lang);

        view.findViewById(R.id.reloadButton).setOnClickListener(v -> {
            if (textWebView != null) {
                Log.d("reload", "TEXT");
                textWebView.reload();
            }

            if (exWebView != null) {
                Log.d("reload", "EX");
                exWebView.reload();
            }

            if (ciWebView != null) {
                Log.d("reload", "CI");
                ciWebView.reload();
            }
        });

        view.findViewById(R.id.showCVTagTestButton).setOnClickListener(v -> {
            Intent intent = new Intent(requireContext(), CVTagTestActivity.class);
            startActivity(intent);
        });

        view.findViewById(R.id.setParamButton).setOnClickListener(v -> {
            itm = itmEdit.getText().toString();
            cid = cidEdit.getText().toString();
            cuid = cuidEdit.getText().toString();
            lang = langEdit.getText().toString();

            if (itm.isEmpty() || cid.isEmpty()) {
                Toast.makeText(requireContext(), "itm、またはcidが未設定です", Toast.LENGTH_SHORT).show();
                return;
            }

            String bnrModeStr = sdkBnrMode.stream()
                    .map(UnisizeBanner.BannerType::name)
                    .collect(Collectors.joining(","));

            Log.d("test", bnrModeStr);

            if ("TEXT".equals(bnrModeStr) || "TEXT,EX".equals(bnrModeStr)) {
                textWebView.setupParam(
                        UnisizeBanner.BannerType.TEXT,
                        sdkBnrMode,
                        itm,
                        cid,
                        cuid,
                        lang,
                        true,
                        true,
                        true,
                        customStyle
                );
                textWebView.addInterfaceToJavaScript(requireContext());
                textWebView.show();
            }

            if ("EX".equals(bnrModeStr) || "TEXT,EX".equals(bnrModeStr)) {
                exWebView.setupParam(
                        UnisizeBanner.BannerType.EX,
                        sdkBnrMode,
                        itm,
                        cid,
                        cuid,
                        lang,
                        true,
                        true,
                        true,
                        customStyle
                );
                exWebView.addInterfaceToJavaScript(requireContext());
                exWebView.show();
            }

            if (ciWebView != null) {
                ciWebView.setupParam(
                        UnisizeBanner.BannerType.CI,
                        sdkBnrMode,
                        itm,
                        cid,
                        cuid,
                        lang,
                        true,
                        true,
                        true,
                        customStyle
                );
                ciWebView.addInterfaceToJavaScript(requireContext());
                ciWebView.show();
            }
        });
    }
}
