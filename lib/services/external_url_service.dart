import 'package:flutter/services.dart';

class ExternalUrlService {
  const ExternalUrlService({
    MethodChannel channel = const MethodChannel('com.lookatlas/external_url'),
  }) : _channel = channel;

  final MethodChannel _channel;

  Future<void> openCheckout(Uri url) async {
    final isStripeCheckout =
        url.scheme == 'https' && url.host == 'checkout.stripe.com';
    final isAppReturn =
        url.scheme == 'lookatlas' &&
        {'/onboarding/success', '/onboarding/activate'}.contains(url.path);
    if (!isStripeCheckout && !isAppReturn) {
      throw ArgumentError.value(url, 'url', 'Untrusted checkout URL.');
    }
    await _channel.invokeMethod<void>('open', {'url': url.toString()});
  }
}
