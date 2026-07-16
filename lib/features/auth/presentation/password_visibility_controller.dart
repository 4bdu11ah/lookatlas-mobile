import 'package:flutter_riverpod/flutter_riverpod.dart';

class PasswordVisibilityController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}

final NotifierProvider<PasswordVisibilityController, bool>
signInPasswordVisibilityProvider =
    NotifierProvider.autoDispose<PasswordVisibilityController, bool>(
      PasswordVisibilityController.new,
    );

final NotifierProvider<PasswordVisibilityController, bool>
signUpPasswordVisibilityProvider =
    NotifierProvider.autoDispose<PasswordVisibilityController, bool>(
      PasswordVisibilityController.new,
    );
