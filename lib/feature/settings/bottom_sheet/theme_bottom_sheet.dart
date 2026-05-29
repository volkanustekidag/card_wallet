import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/controllers/theme_controller.dart';

Future<void> showThemeBottomSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => const _ThemeBottomSheetBody(),
  );
}

class _ThemeBottomSheetBody extends StatelessWidget {
  const _ThemeBottomSheetBody();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ThemeController>();
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Text(
                'theme'.tr(),
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              final selected = controller.appThemeMode;
              return Column(
                children: [
                  _option(
                    context,
                    icon: Icons.light_mode,
                    label: 'themeLight'.tr(),
                    value: AppThemeMode.light,
                    selected: selected,
                    onTap: () {
                      controller.setThemeMode(AppThemeMode.light);
                      Navigator.pop(context);
                    },
                  ),
                  _option(
                    context,
                    icon: Icons.dark_mode,
                    label: 'themeDark'.tr(),
                    value: AppThemeMode.dark,
                    selected: selected,
                    onTap: () {
                      controller.setThemeMode(AppThemeMode.dark);
                      Navigator.pop(context);
                    },
                  ),
                  _option(
                    context,
                    icon: Icons.brightness_auto,
                    label: 'themeSystem'.tr(),
                    value: AppThemeMode.system,
                    selected: selected,
                    onTap: () {
                      controller.setThemeMode(AppThemeMode.system);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _option(
    BuildContext context, {
    required IconData icon,
    required String label,
    required AppThemeMode value,
    required AppThemeMode selected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelected = selected == value;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colorScheme.primary)
          : Icon(Icons.radio_button_unchecked,
              color: colorScheme.onSurface.withValues(alpha: 0.3)),
      onTap: onTap,
    );
  }
}
