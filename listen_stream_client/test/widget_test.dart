import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:listen_stream_client/app.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: ListenStreamApp()));
    // App initializes; router will show login page before any auth state.
    await tester.pump();
  });
}
