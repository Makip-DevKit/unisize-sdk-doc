package jp.co.makip.saas_unisize_sdk_android_kotlin_sample

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.Button
import androidx.fragment.app.Fragment

class TopFragment : Fragment(R.layout.fragment_top) {

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        view.findViewById<Button>(R.id.open_unisize_button).setOnClickListener {
            parentFragmentManager.beginTransaction()
                .replace(R.id.fragment_container, UnisizeFragment())
                .addToBackStack(null)
                .commit()
        }

        view.findViewById<Button>(R.id.open_aunn_button).setOnClickListener {
            startActivity(Intent(requireContext(), AunnCoordinateTestActivity::class.java))
        }

        view.findViewById<Button>(R.id.open_aunn_with_unisize_button).setOnClickListener {
            startActivity(Intent(requireContext(), AunnCoordinateWithUnisizeTestActivity::class.java))
        }
    }
}
