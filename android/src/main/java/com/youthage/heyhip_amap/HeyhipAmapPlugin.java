package com.youthage.heyhip_amap;


import android.Manifest;
import android.app.Activity;
import android.content.Context;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;
import com.amap.api.location.AMapLocationListener;
import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdate;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.model.LatLng;

import java.util.HashMap;
import java.util.Map;


/** HeyhipAmapPlugin */
public class HeyhipAmapPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.RequestPermissionsResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  private Context applicationContext;
  private Activity activity;

  // 权限相关
  private ActivityPluginBinding activityBinding;
  private MethodChannel.Result pendingResult;
  private static final int REQUEST_LOCATION = 10001;

  // 高德使用
  private AMapLocationClient locationClient;
  private MethodChannel.Result locationResult;


  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {

    FlutterEngineHolder.init(flutterPluginBinding.getBinaryMessenger());

    applicationContext = flutterPluginBinding.getApplicationContext();

    
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "heyhip_amap");
    channel.setMethodCallHandler(this);

    // ⭐⭐⭐ 注册 PlatformView（地图）
    flutterPluginBinding.getPlatformViewRegistry().registerViewFactory(
            "heyhip_amap_map",
            new AMapViewFactory()
    );
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
      // case "moveCamera":
      //   moveCamera(call, result);
      //   break;
      case "hasLocationPermission":
            result.success(hasLocationPermission());
            break;
      case "requestLocationPermission":
          requestLocationPermission(result);
          break;
      case "getCurrentLocation":
        getCurrentLocation(result);
        break;
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "initKey":
        handleInit(call, result);
        break;
      case "updatePrivacy":
        handleUpdatePrivacy(call, result);
        break;
      default:
        result.notImplemented();
    }
    
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    channel = null;
  }


  // Activity生命周期

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activity = binding.getActivity();

    activityBinding = binding;

    binding.addRequestPermissionsResultListener(this);
  }

  @Override
  public void onDetachedFromActivity() {
    activity = null;

    if (pendingResult != null) {
      pendingResult.error(
              "ACTIVITY_LOST",
              "Activity was detached before permission result",
              null
      );
      pendingResult = null;
    }

    if (activityBinding != null) {
      activityBinding.removeRequestPermissionsResultListener(this);
      activityBinding = null;
    }
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }



  /// 处理方法

  // 权限检查
  private boolean hasLocationPermission() {
    return ContextCompat.checkSelfPermission(
            applicationContext,
            Manifest.permission.ACCESS_FINE_LOCATION
    ) == PackageManager.PERMISSION_GRANTED;
  }

  // 请求权限
  private void requestLocationPermission(MethodChannel.Result result) {

    if (activity == null) {
      result.error(
              "NO_ACTIVITY",
              "Activity not attached",
              null
      );
      return;
    }

    if (hasLocationPermission()) {
      result.success(true);
      return;
    }

    if (pendingResult != null) {
      result.error(
              "PERMISSION_IN_PROGRESS",
              "Permission request already in progress",
              null
      );
      return;
    }

    pendingResult = result;

    ActivityCompat.requestPermissions(
            activity,
            new String[]{
                    Manifest.permission.ACCESS_FINE_LOCATION
            },
            REQUEST_LOCATION
    );
  }

  // 接收系统回调
  @Override
  public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    if (requestCode == REQUEST_LOCATION) {

      boolean granted =
              grantResults.length > 0 &&
                      grantResults[0] == PackageManager.PERMISSION_GRANTED;

      if (pendingResult != null) {
        pendingResult.success(granted);
        pendingResult = null;
      }

      return true;
    }

    return false;
  }

  // 地图初始化
  private void handleInit(MethodCall call, MethodChannel.Result result) {
    String apiKey = call.argument("apiKey");
    // Boolean agreePrivacy = call.argument("agreePrivacy");

    if (apiKey == null || apiKey.isEmpty()) {
      result.error(
              "INVALID_API_KEY",
              "apiKey is null or empty",
              null
      );
      return;
    }

    if (applicationContext == null) {
      result.error(
              "NO_CONTEXT",
              "Application context not available",
              null
      );
      return;
    }

    if (activity == null) {
      result.error(
              "NO_ACTIVITY",
              "Activity not attached",
              null
      );
      return;
    }


    // 高德地图初始化
    try {
      // ⚠️ 高德 10.x：Key 不需要代码设置
      // 这里只是做一次合法性校验 & 占位
      // 真正 Key 在 AndroidManifest.xml 的 meta-data

      result.success(null);
    } catch (Exception e) {
      result.error("INIT_FAILED", e.getMessage(), null);
    }
  }

  // 隐私
  private void handleUpdatePrivacy(MethodCall call, MethodChannel.Result result) {
    Boolean hasContains = call.argument("hasContains");
    Boolean hasShow = call.argument("hasShow");
    Boolean hasAgree = call.argument("hasAgree");

    if (hasContains == null || hasShow == null || hasAgree == null) {
      result.error(
              "INVALID_ARGS",
              "Privacy arguments missing",
              null
      );
      return;
    }

    if (applicationContext == null) {
      result.error(
              "NO_CONTEXT",
              "Application context not available",
              null
      );
      return;
    }

    try {
      // ✅ 10.x SDK 必须顺序调用
      AMapLocationClient.updatePrivacyShow(
              applicationContext,
              hasContains,
              hasShow
      );

      AMapLocationClient.updatePrivacyAgree(
              applicationContext,
              hasAgree
      );

      result.success(null);
    } catch (Exception e) {
      result.error("PRIVACY_FAILED", e.getMessage(), null);
    }
  }


  // 获取当前定位
  private void getCurrentLocation(MethodChannel.Result result) {

    if (activity == null) {
      result.error("NO_ACTIVITY", "Activity not attached", null);
      return;
    }

    if (!hasLocationPermission()) {
      result.error("NO_PERMISSION", "Location permission not granted", null);
      return;
    }

    locationResult = result;

    try {
      locationClient = new AMapLocationClient(activity.getApplicationContext());

      AMapLocationClientOption option = new AMapLocationClientOption();
      option.setLocationMode(
              AMapLocationClientOption.AMapLocationMode.Hight_Accuracy
      );
      option.setOnceLocation(true); // 只定位一次
      option.setNeedAddress(true);

      locationClient.setLocationOption(option);

      locationClient.setLocationListener(new AMapLocationListener() {
        @Override
        public void onLocationChanged(AMapLocation location) {

          if (locationResult == null) return;

          if (location != null && location.getErrorCode() == 0) {

            Map<String, Object> map = new HashMap<>();
            map.put("latitude", location.getLatitude());
            map.put("longitude", location.getLongitude());
            map.put("accuracy", location.getAccuracy());
            map.put("address", location.getAddress());

            locationResult.success(map);
          } else {
            locationResult.error(
                    "LOCATION_FAILED",
                    location == null
                            ? "location is null"
                            : location.getErrorInfo(),
                    null
            );
          }

          locationResult = null;

          if (locationClient != null) {
            locationClient.stopLocation();
            locationClient.onDestroy();
            locationClient = null;
          }
        }
      });

      locationClient.startLocation();

    } catch (Exception e) {
      result.error("LOCATION_EXCEPTION", e.getMessage(), null);
    }
  }

  // // 移动
  // private void moveCamera(MethodCall call, Result result) {
  //
  //   double lat = call.argument("latitude");
  //   double lng = call.argument("longitude");
  //   double zoom = ((Number) call.argument("zoom")).doubleValue();
  //
  //   // 目前只有一个地图，直接取第一个
  //   AMap aMap = AMapPlatformView.MAPS.values().iterator().next();
  //
  //   if (aMap == null) {
  //     result.error("NO_MAP", "Map not ready", null);
  //     return;
  //   }
  //
  //   CameraUpdate update = CameraUpdateFactory.newLatLngZoom(
  //           new LatLng(lat, lng),
  //           (float) zoom
  //   );
  //
  //   aMap.animateCamera(update);
  //   result.success(null);
  // }


}
