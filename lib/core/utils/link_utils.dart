import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Small helpers for opening external links (video submissions, invite links)
/// and copying text to the clipboard, with consistent user feedback.
class LinkUtils {
  /// Opens [url] in an external browser/app. Surfaces a SnackBar if the link
  /// is missing, malformed, or cannot be launched.
  static Future<void> openExternal(BuildContext context, String? url) async {
    final messenger = ScaffoldMessenger.of(context);
    final trimmed = url?.trim() ?? '';
    if (trimmed.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text('No link to open')));
      return;
    }

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !(uri.hasScheme && uri.hasAuthority)) {
      messenger.showSnackBar(const SnackBar(content: Text('Invalid link')));
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      messenger.showSnackBar(SnackBar(content: Text('Could not open $trimmed')));
    }
  }

  /// Copies [text] to the clipboard and confirms with a SnackBar.
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String label = 'Copied',
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$label to clipboard')),
      );
    }
  }
}
