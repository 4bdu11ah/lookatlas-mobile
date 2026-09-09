import 'package:dio/dio.dart';
import 'package:look_atlas/core/network/request_cancellation.dart';

class DioCancellation {
  DioCancellation(RequestCancellation? cancellation) {
    token = CancelToken();
    _removeListener = cancellation?.addListener(token.cancel);
  }

  late final CancelToken token;
  void Function()? _removeListener;

  void dispose() {
    _removeListener?.call();
    _removeListener = null;
    if (!token.isCancelled) token.cancel();
  }
}
