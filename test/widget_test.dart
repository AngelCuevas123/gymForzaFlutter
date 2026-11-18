import 'package:flutter_test/flutter_test.dart';
import 'package:gym_forza_flutter/main.dart';

void main() {
  testWidgets('shows Supabase setup instructions when credentials are absent',
      (WidgetTester tester) async {
    await tester.pumpWidget(const App(configured: false));

    expect(find.text('GYM FORZA'), findsOneWidget);
    expect(find.text('Falta configurar Supabase'), findsOneWidget);
    expect(find.textContaining('SUPABASE_PUBLISHABLE_KEY'), findsOneWidget);
  });
}
