import 'package:flutter/material.dart';
import 'package:look_atlas/core/theme/app_colors.dart';

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = true,
  Color backgroundColor = AppColors.white,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    shape: const RoundedRectangleBorder(),
    builder: builder,
  );
}
