import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../app/router.dart';
import '../../core/theme/app_motion.dart';
import '../../state/cart_controller.dart';

/// AppBar cart icon with animated quantity badge.
class CartBadgeIcon extends StatelessWidget {
  const CartBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CartController>(
      builder: (context, cart, _) {
        final count = cart.totalQuantity;
        return IconButton(
          tooltip: 'Giỏ hàng',
          onPressed: () => context.go(AppRoutes.cart),
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text(count > 99 ? '99+' : '$count'),
            child: TweenAnimationBuilder<double>(
              key: ValueKey(count),
              tween: Tween(begin: 0.85, end: 1),
              duration: AppMotion.badge,
              curve: AppMotion.badgeCurve,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        );
      },
    );
  }
}
