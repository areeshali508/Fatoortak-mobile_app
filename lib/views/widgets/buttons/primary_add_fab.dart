import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class PrimaryAddFab extends StatelessWidget {
  final VoidCallback? onPressed;

  const PrimaryAddFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 62,
      height: 62,
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
