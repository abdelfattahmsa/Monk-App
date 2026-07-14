import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';

// ══════════════════════════════════════════════════════════════
// SHARED PLACEHOLDER WIDGETS — Monk
// ══════════════════════════════════════════════════════════════

// ── SCREEN HEADER ─────────────────────────────────────────────
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineLarge),
              if (subtitle != null) ...[
                const Gap(4),
                Text(
                  subtitle!,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: textSecondary),
                ),
              ],
            ],
          ),
        ),
        if (action != null) action!,
      ],
    );
  }
}

// ── SECTION HEADER ────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title,
      {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textSecondary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
        ),
        if (action != null)
          GestureDetector(
            onTap: onAction ?? () {},
            child: Text(
              action!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
      ],
    );
  }
}

// ── STAT CARD ─────────────────────────────────────────────────
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trend,
    this.trendUp,
  });
  final String label;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final String? trend;
  final bool? trendUp;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = iconColor ?? Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Container(
      padding: const EdgeInsets.all(Spacing.base),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: textSecondary,
                        letterSpacing: 0.3,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const Gap(4),
                Icon(icon, size: 14,
                    color: accent.withValues(alpha: 0.7)),
              ],
            ],
          ),
          const Gap(Spacing.sm),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (subtitle != null) ...[
            const Gap(2),
            Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: textSecondary),
            ),
          ],
          if (trend != null) ...[
            const Gap(Spacing.xs),
            Row(
              children: [
                Icon(
                  trendUp == true
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 12,
                  color: trendUp == true
                      ? AppColors.success
                      : AppColors.error,
                ),
                const Gap(3),
                Text(
                  trend!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: trendUp == true
                            ? AppColors.success
                            : AppColors.error,
                      ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── STATS GRID (responsive 2-column) ─────────────────────────
class StatsGrid extends StatelessWidget {
  const StatsGrid({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i += 2) {
      if (i > 0) rows.add(const Gap(Spacing.sm));
      rows.add(Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: children[i]),
          if (i + 1 < children.length) ...[
            const Gap(Spacing.sm),
            Expanded(child: children[i + 1]),
          ] else
            const Expanded(child: SizedBox()),
        ],
      ));
    }
    return Column(children: rows);
  }
}

// ── PLACEHOLDER CHART ─────────────────────────────────────────
class PlaceholderChart extends StatelessWidget {
  const PlaceholderChart({
    super.key,
    this.height = 160,
    this.data,
    this.label,
  });
  final double height;
  final List<double>? data;
  final String? label;

  static const _default = [3.2, 4.5, 3.8, 5.2, 4.1, 6.0, 5.4];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: CustomPaint(
                painter: _LineChartPainter(
                  accent: accent,
                  gridColor: isDark ? AppColors.border : AppColors.lightBorder,
                  data: data ?? _default,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          if (label != null)
            Positioned(
              left: 14,
              top: 10,
              child: Text(
                label!,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: textSecondary,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
    required this.accent,
    required this.gridColor,
    required this.data,
  });
  final Color accent;
  final Color gridColor;
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = (maxVal - minVal).abs();
    final effectiveRange = range < 0.001 ? 1.0 : range;
    const padTop = 0.08;
    const padBottom = 0.12;

    Offset toPoint(int i) {
      final x = size.width * i / (data.length - 1);
      final norm = (data[i] - minVal) / effectiveRange;
      final y = size.height * (padTop + (1 - padTop - padBottom) * (1 - norm));
      return Offset(x, y);
    }

    // Grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * (padTop + (1 - padTop - padBottom) * i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Line path
    final path = Path();
    path.moveTo(toPoint(0).dx, toPoint(0).dy);
    for (var i = 1; i < data.length; i++) {
      final prev = toPoint(i - 1);
      final curr = toPoint(i);
      final cpx = (prev.dx + curr.dx) / 2;
      path.cubicTo(cpx, prev.dy, cpx, curr.dy, curr.dx, curr.dy);
    }

    // Fill
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    canvas.drawPath(
      path,
      Paint()
        ..color = accent
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Dots
    for (var i = 0; i < data.length; i++) {
      final pt = toPoint(i);
      canvas.drawCircle(pt, 3.5, Paint()..color = accent.withValues(alpha: 0.2));
      canvas.drawCircle(pt, 2, Paint()..color = accent);
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.accent != accent || old.data != data;
}

// ── PLACEHOLDER LIST ──────────────────────────────────────────
class PlaceholderListItem {
  const PlaceholderListItem({
    required this.title,
    this.subtitle,
    this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final String? value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
}

class PlaceholderList extends StatelessWidget {
  const PlaceholderList({super.key, required this.items});
  final List<PlaceholderListItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: borderColor),
            _PlaceholderListTile(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _PlaceholderListTile extends StatelessWidget {
  const _PlaceholderListTile({required this.item});
  final PlaceholderListItem item;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = item.iconColor ?? Theme.of(context).colorScheme.primary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.base, vertical: Spacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon ?? Icons.circle_outlined,
                size: 18, color: accent),
          ),
          const Gap(Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
                if (item.subtitle != null)
                  Text(
                    item.subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: textSecondary),
                  ),
              ],
            ),
          ),
          if (item.trailing != null)
            item.trailing!
          else if (item.value != null)
            Text(
              item.value!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: item.valueColor,
                  ),
            ),
        ],
      ),
    );
  }
}

// ── SETTINGS TILES ─────────────────────────────────────────────
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Spacing.base, vertical: 2),
      leading: leading,
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: textSecondary),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(Icons.chevron_right_rounded,
                  size: 18, color: textSecondary)
              : null),
      onTap: onTap,
    );
  }
}

class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Spacing.base, vertical: 2),
      leading: leading,
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: textSecondary),
            )
          : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

// ── SECTION CARD ──────────────────────────────────────────────
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}
