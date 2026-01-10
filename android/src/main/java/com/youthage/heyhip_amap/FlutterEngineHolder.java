package com.youthage.heyhip_amap;

import io.flutter.plugin.common.BinaryMessenger;

public final class FlutterEngineHolder {

    private static BinaryMessenger messenger;

    private FlutterEngineHolder() {
        // 禁止实例化
    }

    public static void init(BinaryMessenger m) {
        messenger = m;
    }

    public static BinaryMessenger getMessenger() {
        if (messenger == null) {
            throw new IllegalStateException(
                    "FlutterEngineHolder is not initialized"
            );
        }
        return messenger;
    }
}
