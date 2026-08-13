import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:look_atlas/shared/widgets/app_text_field.dart';
import 'package:look_atlas/shared/widgets/primary_button.dart';

class AssistantComposer extends StatelessWidget {
  const AssistantComposer({
    required this.controller,
    required this.enabled,
    required this.canSend,
    required this.onSend,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final remaining = 2000 - controller.text.characters.length;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Focus(
            onKeyEvent: (_, event) {
              final enter =
                  event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.enter;
              if (enter && !HardwareKeyboard.instance.isShiftPressed) {
                if (canSend) onSend();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Row(
              key: const Key('assistant-composer-row'),
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: IgnorePointer(
                    ignoring: !enabled,

                    child: AppTextField(
                      controller: controller,
                      fieldKey: const Key('assistant-composer'),
                      hintText: 'Ask anything about Look Atlas',
                      maxLines: 5,
                      maxLength: 2000,
                      showCounter: false,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Semantics(
                  button: true,
                  label: 'Send message',
                  child: SizedBox.square(
                    dimension: 48,
                    child: PrimaryButton(
                      key: const Key('assistant-send'),
                      onPressed: canSend ? onSend : null,
                      fitToContent: true,
                      iconSize: 18,
                      child: const Icon(Icons.send, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (remaining <= 200)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '$remaining characters left',
                  style: const TextStyle(
                    color: Color(0x660A0A0A),
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
