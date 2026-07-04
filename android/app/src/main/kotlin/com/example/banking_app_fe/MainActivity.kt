package com.example.banking_app_fe

import io.flutter.embedding.android.FlutterFragmentActivity

// local_auth requires a FragmentActivity host to show the biometric prompt,
// so we extend FlutterFragmentActivity instead of the default FlutterActivity.
class MainActivity : FlutterFragmentActivity()
