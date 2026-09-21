import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';

class ChatComposer extends StatefulWidget {
  final AppStrings strings;
  final String? selectedText;
  final VoidCallback onClearSelectedText;
  final ValueChanged<String> onSend;
  final bool isStreaming;
  final VoidCallback onStop;

  const ChatComposer({
    super.key,
    required this.strings,
    this.selectedText,
    required this.onClearSelectedText,
    required this.onSend,
    required this.isStreaming,
    required this.onStop,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text;
    if (text.trim().isNotEmpty) {
      widget.onSend(text);
      _controller.clear();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final hasInput = _controller.text.trim().isNotEmpty;
    final strings = widget.strings;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Text Selection Chip Preview
          if (widget.selectedText != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colors.selectionBackground,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.format_quote, size: 14, color: colors.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.selectedText!,
                      style: AppTypography.caption.copyWith(
                        color: colors.primary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: widget.onClearSelectedText,
                    child: Icon(Icons.close, size: 14, color: colors.primary),
                  ),
                ],
              ),
            ),
          ],

          // Input Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment / Clip icon
              Padding(
                padding: const EdgeInsets.only(bottom: 6, right: 6),
                child: Tooltip(
                  message: strings.selectedScope,
                  child: Icon(
                    Icons.attach_file,
                    size: 18,
                    color: widget.selectedText != null ? colors.primary : colors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ),

              // Text Field
              Expanded(
                child: Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                      if (!HardwareKeyboard.instance.isShiftPressed &&
                          _controller.value.composing == TextRange.empty) {
                        _handleSend();
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    style: AppTypography.body.copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: strings.askAboutPaper,
                      hintStyle: AppTypography.body.copyWith(
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: colors.appBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),

              const SizedBox(width: 8),

              // Send or Stop Button
              if (widget.isStreaming)
                IconButton(
                  icon: const Icon(Icons.stop_circle_outlined, size: 24),
                  color: colors.error,
                  onPressed: widget.onStop,
                )
              else
                Material(
                  color: hasInput ? colors.primary : colors.divider,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: hasInput ? _handleSend : null,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Icon(
                        Icons.send_rounded,
                        size: 16,
                        color: hasInput ? colors.onPrimary : colors.textSecondary,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Subtitle tag line
          Center(
            child: Text(
              strings.answersCrossReferenced,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: colors.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
