import 'package:flutter/material.dart';

class AppSpacedColumn extends StatelessWidget {
  const AppSpacedColumn({required this.children, this.gap = 20, super.key});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) SizedBox(height: gap),
        ],
      ],
    );
  }
}
