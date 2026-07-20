import 'package:flutter/material.dart';

import '../../core/theme/app_radii.dart';

/// Quantity control with ≥44px hit targets.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.min = 1,
    this.max,
    super.key,
  });

  final int quantity;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final int min;
  final int? max;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canDec = quantity > min && onDecrement != null;
    final canInc = (max == null || quantity < max!) && onIncrement != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadii.borderMd,
        border: Border.all(color: cs.outlineVariant.withValues(alpha: .5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            onPressed: canDec ? onDecrement : null,
          ),
          Container(
            width: 40,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: .5),
                ),
              ),
            ),
            child: Text(
              '$quantity',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            onPressed: canInc ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
      ),
    );
  }
}
