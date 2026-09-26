import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:paper_chat/app/localization/app_strings.dart';
import 'package:paper_chat/app/theme/app_colors.dart';
import 'package:paper_chat/app/theme/app_typography.dart';
import 'package:paper_chat/models/chat_message.dart';
import 'package:paper_chat/features/chat/widgets/citation_chip.dart';
import 'package:paper_chat/services/doi_service.dart';
import 'package:paper_chat/shared/widgets/math_markdown_builder.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

class MessageBubble extends StatelessWidget {
  final AppStrings strings;
  final ChatMessage message;
  final void Function(int page, String excerpt) onCitationTap;
  final VoidCallback onSaveNote;
  final VoidCallback onRetry;

  const MessageBubble({
    super.key,
    required this.strings,
    required this.message,
    required this.onCitationTap,
    required this.onSaveNote,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColorsExtension.of(context);
    final isUser = message.role == MessageRole.user;
    final formattedTime = '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}';

    if (isUser) {
      // User Message: Aligned to the RIGHT
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // User Header (Name & Time aligned right)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  formattedTime,
                  style: AppTypography.caption.copyWith(
                    color: colors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  strings.userRole,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      'B',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Quoted text context if user selected text before asking
            if (message.selectedText != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                margin: const EdgeInsets.only(bottom: 4),
                decoration: BoxDecoration(
                  color: colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border(right: BorderSide(color: colors.primary, width: 3)),
                ),
                child: Text(
                  '"${message.selectedText!}"',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colors.textSecondary,
                  ),
                ),
              ),

            // User Message Bubble Container
            Container(
              constraints: const BoxConstraints(maxWidth: 340),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.selectionBackground,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Text(
                message.content,
                style: AppTypography.body.copyWith(
                  color: colors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // AI Assistant Message: Aligned to the LEFT
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Header (Avatar, Assistant Name, Time)
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.smart_toy_outlined,
                    size: 13,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strings.assistantRole,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                formattedTime,
                style: AppTypography.caption.copyWith(
                  color: colors.textSecondary.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // AI Message Content Body (Left padded)
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: message.content + (message.isStreaming ? ' ▋' : ''),
                  selectable: true,
                  extensionSet: md.ExtensionSet.gitHubFlavored,
                  inlineSyntaxes: [MathSyntax()],
                  builders: {'math': MathBuilder(textStyle: AppTypography.body.copyWith(color: colors.textPrimary))},
                  onTapLink: (text, href, title) async {
                    if (href == null || href.isEmpty) return;
                    if (DoiService.isValidDoi(href)) {
                      await DoiService.openDoi(href);
                    } else {
                      final uri = Uri.tryParse(href);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    p: AppTypography.body.copyWith(color: colors.textPrimary, height: 1.5),
                    h1: AppTypography.subtitle.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold),
                    h2: AppTypography.body.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold),
                    h3: AppTypography.caption.copyWith(color: colors.textPrimary, fontWeight: FontWeight.bold),
                    listBullet: AppTypography.body.copyWith(color: colors.textPrimary),
                    code: AppTypography.code.copyWith(
                      backgroundColor: colors.surfaceElevated,
                      color: colors.primary,
                    ),
                  ),
                ),

                // Inline Citations Chips
                if (message.citations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: message.citations.map((c) {
                      return CitationChip(
                        label: c.label,
                        excerpt: c.excerpt,
                        isVi: strings.isVi,
                        onTap: () => onCitationTap(c.page, c.excerpt),
                      );
                    }).toList(),
                  ),

                  // Quoted Source Snippet Card
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () => onCitationTap(
                      message.citations.first.page,
                      message.citations.first.excerpt,
                    ),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${strings.source} · ${strings.page} ${message.citations.first.page + 1}',
                                style: AppTypography.caption.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.arrow_forward, size: 12, color: colors.textSecondary),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            message.citations.first.excerpt,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption.copyWith(
                              color: colors.textSecondary,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Action Row: Copy & Save Note
                if (!message.isStreaming && !message.isError) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: message.content));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(strings.copiedToClipboard),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.copy_outlined, size: 13, color: colors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                strings.copy,
                                style: AppTypography.caption.copyWith(color: colors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: onSaveNote,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Row(
                            children: [
                              Icon(Icons.bookmark_outline, size: 13, color: colors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                strings.saveNote,
                                style: AppTypography.caption.copyWith(color: colors.textSecondary, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                if (message.isError) ...[
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: onRetry,
                    icon: Icon(Icons.refresh, size: 14, color: colors.error),
                    label: Text(strings.retry, style: AppTypography.caption.copyWith(color: colors.error)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
