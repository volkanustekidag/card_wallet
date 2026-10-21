import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wallet_app/core/data/storage/encrypted_box_opener.dart';
import 'package:wallet_app/feature/boot/boot_error_page.dart';
import 'package:wallet_app/feature/boot/boot_gate.dart';

const _app = Directionality(
  textDirection: TextDirection.ltr,
  child: Text('wallet home'),
);

void main() {
  testWidgets('auth init throws: runApp is still called with BootErrorPage',
      (tester) async {
    var bootCalls = 0;
    var keychainLocked = true;
    Future<void> boot() async {
      bootCalls++;
      if (keychainLocked) {
        throw StorageUnavailableException(
          'login',
          PlatformException(code: '-25308'),
        );
      }
    }

    Widget? root;
    await bootAndRunApp(
      boot: boot,
      wrap: (gate) => gate,
      app: _app,
      run: (widget) => root = widget,
    );

    expect(root, isNotNull, reason: 'runApp must be called');
    await tester.pumpWidget(root!);
    expect(find.byType(BootErrorPage), findsOneWidget);
    expect(find.text('wallet home'), findsNothing);
    expect(find.text(BootErrorPage.supportEmail), findsOneWidget);

    // Still locked: retry keeps the error page.
    await tester.tap(find.byKey(const Key('bootErrorRetry')));
    await tester.pumpAndSettle();
    expect(bootCalls, 2);
    expect(find.byType(BootErrorPage), findsOneWidget);

    // Unlocked: retry boots into the app.
    keychainLocked = false;
    await tester.tap(find.byKey(const Key('bootErrorRetry')));
    await tester.pumpAndSettle();
    expect(bootCalls, 3);
    expect(find.byType(BootErrorPage), findsNothing);
    expect(find.text('wallet home'), findsOneWidget);
  });

  testWidgets('returning to the foreground retries the boot', (tester) async {
    var keychainLocked = true;
    Future<void> boot() async {
      if (keychainLocked) throw Exception('keystore');
    }

    await tester.pumpWidget(BootGate(
      boot: boot,
      initialError: Exception('keystore'),
      child: _app,
    ));
    expect(find.byType(BootErrorPage), findsOneWidget);

    keychainLocked = false;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('wallet home'), findsOneWidget);
  });

  testWidgets('successful boot goes straight to the app', (tester) async {
    Widget? root;
    await bootAndRunApp(
      boot: () async {},
      wrap: (gate) => gate,
      app: _app,
      run: (widget) => root = widget,
    );

    await tester.pumpWidget(root!);
    expect(find.byType(BootErrorPage), findsNothing);
    expect(find.text('wallet home'), findsOneWidget);
  });
}
