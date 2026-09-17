import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class OnlineSwitch extends StatelessWidget {
  final bool online;
  final ValueChanged<bool> onChanged;

  const OnlineSwitch({
    super.key,
    required this.online,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!online),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: online
              ? FoodJetColors.green.withOpacity(.12)
              : Colors.black.withOpacity(.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: online
                ? FoodJetColors.green.withOpacity(.25)
                : Colors.black.withOpacity(.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: online
                    ? FoodJetColors.green
                    : Colors.grey,
              ),
            ),
            const SizedBox(width: 9),
            Text(
              online ? 'ONLINE' : 'OFFLINE',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: online
                    ? FoodJetColors.green
                    : FoodJetColors.gray,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
