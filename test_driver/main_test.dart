import 'package:flutter_driver/driver_extension.dart';

import 'package:flutter_app/main.dart' as app;

/// نقطة تشغيل مخصصة للاستكشاف الآلي فقط، ولا تدخل في بناء الإنتاج.
void main() {
  enableFlutterDriverExtension();
  app.main();
}
