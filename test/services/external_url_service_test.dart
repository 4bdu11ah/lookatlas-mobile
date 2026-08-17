import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:look_atlas/services/external_url_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/external_url');
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('open_checkout_accepts_only_stripe_checkout_host', () async {
    const service = ExternalUrlService(channel: channel);

    await service.openCheckout(
      Uri.parse('https://checkout.stripe.com/c/pay/cs_test'),
    );

    expect(calls.single.method, 'open');
    expect(
      () => service.openCheckout(Uri.parse('https://stripe.example.com/pay')),
      throwsArgumentError,
    );
  });

  test('open_calendly_accepts_only_secure_calendly_host', () async {
    const service = ExternalUrlService(channel: channel);

    await service.openCalendly(
      Uri.parse('https://calendly.com/lookatlas/customer-onboarding'),
    );

    expect(calls.single.method, 'open');
    expect(
      () => service.openCalendly(Uri.parse('https://calendly.example.com')),
      throwsArgumentError,
    );
  });
}
