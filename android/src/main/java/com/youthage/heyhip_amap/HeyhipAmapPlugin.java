package com.youthage.heyhip_amap;


import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** HeyhipAmapPlugin */
public class HeyhipAmapPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private Context applicationContext;
  private Activity activity;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {

    applicationContext = flutterPluginBinding.getApplicationContext();

    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "heyhip_amap");
    channel.setMethodCallHandler(this);
  }

  // @Override
  // public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
  //   if (call.method.equals("getPlatformVersion")) {
  //     result.success("Android " + android.os.Build.VERSION.RELEASE);
  //   } else {
  //     result.notImplemented();
  //   }
  // }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "init":
        handleInit(call, result);
        break;
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      default:
        result.notImplemented();
    }
    
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }


  // Activity生命周期


  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activity = null;
  }

  /// 处理方法
  private void handleInit(MethodCall call,
                          MethodChannel.Result result) {
    String apiKey = call.argument("apiKey");
    Boolean agreePrivacy = call.argument("agreePrivacy");

    if (apiKey == null || apiKey.isEmpty()) {
      result.error(
              "INVALID_API_KEY",
              "apiKey is null or empty",
              null
      );
      return;
    }

    if (agreePrivacy == null || !agreePrivacy) {
      result.error(
              "PRIVACY_NOT_AGREED",
              "User has not agreed privacy policy",
              null
      );
      return;
    }

    // 高德地图初始化


    result.success(null);
  }


}
