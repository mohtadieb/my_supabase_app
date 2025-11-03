import 'dart:async';
import 'package:flutter/material.dart';

class TimeAgoText extends StatefulWidget {
  /// The createdAt DateTime from Supabase (already a DateTime object)
  final DateTime createdAt;

  /// Optional TextStyle for customization
  final TextStyle? style;

  const TimeAgoText({
    super.key,
    required this.createdAt,
    this.style,
  });

  @override
  State<TimeAgoText> createState() => _TimeAgoTextState();
}

class _TimeAgoTextState extends State<TimeAgoText> {
  late DateTime createdAtUtc;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Convert to UTC once for safe comparison
    createdAtUtc = widget.createdAt.toUtc();

    // Timer to update the text every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String getTimeAgo() {
    final nowUtc = DateTime.now().toUtc();
    final diff = nowUtc.difference(createdAtUtc);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    // Older than a week, show full date
    return '${createdAtUtc.day}/${createdAtUtc.month}/${createdAtUtc.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      getTimeAgo(),
      style: widget.style,
    );
  }
}