import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../app/theme.dart';
import 'assistant_screen.dart';
import 'assistant_service.dart';

@Preview(
  name: 'Lugta assistant — consent and chat',
  group: 'Assistant',
  size: Size(390, 844),
)
Widget assistantPreview() => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light(),
  home: Directionality(
    textDirection: TextDirection.rtl,
    child: AssistantScreen(
      send: (message, history) async => const AssistantAnswer(
        'هذه معاينة فقط. بالنسخة المرتبطة بالسيرفر أجاوبك اعتماداً على قاعدة المعرفة والمنتجات المتاحة.',
      ),
    ),
  ),
);
