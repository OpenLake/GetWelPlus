/// Maps technical errors into a friendly message suitable for end users.
///
/// This is intentionally conservative: most errors are surfaced as-is,
/// but common networking failures (e.g. "connection reset") are replaced
/// with a gentle, actionable message that doesn't expose raw exception text.
String friendlyErrorMessage(Object error, {String? fallback}) {
  final message = error.toString();

  // Network / connectivity issues we want to hide from users
  if (message.contains('Connection reset') ||
      message.contains('Failed host lookup') ||
      message.contains('Network is unreachable') ||
      message.contains('Connection refused') ||
      message.contains('Connection timed out') ||
      message.contains('SocketException') ||
      message.contains('HttpException')) {
    return fallback ??
        'Oops—looks like we hit a connection hiccup. Please try again in a moment — don\'t fret, it\'s on us.';
  }

  return message;
}
