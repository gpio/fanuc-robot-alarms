import 'package:flutter/material.dart';

import '../models/error_code.dart';

class DetailScreen extends StatelessWidget {
  final ErrorCode error;

  const DetailScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(error.code),
        backgroundColor: _typeColor(error.type),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TypeBadge(type: error.type),
            const SizedBox(height: 16),
            _Section(
              icon: Icons.warning_amber_rounded,
              title: 'Alarm',
              content: error.message,
              contentStyle: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (error.cause.isNotEmpty) ...[
              const Divider(height: 32),
              _Section(
                icon: Icons.help_outline,
                title: 'Cause',
                content: error.cause,
              ),
            ],
            if (error.remedy.isNotEmpty) ...[
              const Divider(height: 32),
              _Section(
                icon: Icons.build_circle_outlined,
                title: 'Remedy',
                content: error.remedy,
                contentStyle: const TextStyle(color: Color(0xFF1B5E20)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    return switch (type) {
      'FATAL' => const Color(0xFFB71C1C),
      'ABORT' || 'ABORT.G' || 'ABORT.L' || 'ABRT' || 'SABRT' =>
        const Color(0xFFE53935),
      'PAUSE' || 'PAUSE.G' || 'PAUSE.L' || 'PAUS' => const Color(0xFFF57C00),
      'WARN' => const Color(0xFFF9A825),
      'SERVO' || 'SERVO2' => const Color(0xFF1565C0),
      'STOP' || 'STOPL' || 'SVSTOP' => const Color(0xFF6A1B9A),
      'SYSTEM' => const Color(0xFF37474F),
      _ => const Color(0xFF455A64),
    };
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _bg(type),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.isEmpty ? 'INFO' : type,
        style: TextStyle(
          color: _fg(type),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _bg(String type) => switch (type) {
        'FATAL' => const Color(0xFFFFCDD2),
        'ABORT' || 'ABORT.G' || 'ABORT.L' || 'ABRT' || 'SABRT' =>
          const Color(0xFFFFCDD2),
        'PAUSE' || 'PAUSE.G' || 'PAUSE.L' || 'PAUS' => const Color(0xFFFFE0B2),
        'WARN' => const Color(0xFFFFF9C4),
        'SERVO' || 'SERVO2' => const Color(0xFFBBDEFB),
        'STOP' || 'STOPL' || 'SVSTOP' => const Color(0xFFE1BEE7),
        'SYSTEM' => const Color(0xFFECEFF1),
        _ => const Color(0xFFECEFF1),
      };

  Color _fg(String type) => switch (type) {
        'FATAL' => const Color(0xFFB71C1C),
        'ABORT' || 'ABORT.G' || 'ABORT.L' || 'ABRT' || 'SABRT' =>
          const Color(0xFFB71C1C),
        'PAUSE' || 'PAUSE.G' || 'PAUSE.L' || 'PAUS' => const Color(0xFFE65100),
        'WARN' => const Color(0xFFF57F17),
        'SERVO' || 'SERVO2' => const Color(0xFF0D47A1),
        'STOP' || 'STOPL' || 'SVSTOP' => const Color(0xFF4A148C),
        'SYSTEM' => const Color(0xFF263238),
        _ => const Color(0xFF263238),
      };
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final TextStyle? contentStyle;

  const _Section({
    required this.icon,
    required this.title,
    required this.content,
    this.contentStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: contentStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
