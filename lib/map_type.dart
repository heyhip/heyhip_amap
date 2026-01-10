enum MapType {
  normal,     // 普通
  satellite,  // 卫星
  night,      // 夜间
  navi,       // 导航
  bus,        // 公交
}


extension MapTypeExt on MapType {
  int get value {
    switch (this) {
      case MapType.normal:
        return 0;
      case MapType.satellite:
        return 1;
      case MapType.night:
        return 2;
      case MapType.navi:
        return 3;
      case MapType.bus:
        return 4;
    }
  }
}

