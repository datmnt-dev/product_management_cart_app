import 'package:flutter/material.dart';

import '../../core/utils/formatters.dart';

/// Primary price display using brand color.
class PriceText extends StatelessWidget {
  const PriceText(
    this.amount, {
    this.fontSize = 13,
    this.maxLines = 1,
    super.key,
  });

  final num amount;
  final double fontSize;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      formatCurrency(amount),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: cs.primary,
        fontWeight: FontWeight.w900,
        fontSize: fontSize,
        letterSpacing: -0.2,
      ),
    );
  }
}
