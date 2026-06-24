import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:svga_previewer/main.dart';
import 'package:svga_previewer/view_models/animation_view_model.dart';

void main() {
  testWidgets('app renders theme controls and actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AnimationViewModel(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('主题模式:'), findsOneWidget);
    expect(find.text('背景颜色:'), findsOneWidget);
    expect(find.byTooltip('从 URL 下载'), findsOneWidget);
    expect(find.byTooltip('打开动画文件'), findsOneWidget);
  });
}
