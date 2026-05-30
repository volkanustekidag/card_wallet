import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;

Future<bool?> showLangChoseeBottomSheet(BuildContext context) async {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const LanguageBottomSheetBody(),
  );
}

class LanguageBottomSheetBody extends StatefulWidget {
  const LanguageBottomSheetBody({Key? key}) : super(key: key);

  @override
  State<LanguageBottomSheetBody> createState() =>
      _LanguageBottomSheetBodyState();
}

class _LanguageBottomSheetBodyState extends State<LanguageBottomSheetBody> {
  int _selectedIndex = 0;

  static const List<Locale> _supportedLocales = [
    Locale("en", "US"),
    Locale("tr", "TR"),
    Locale("de", "DE"),
    Locale("fr", "FR"),
    Locale("es", "ES"),
    Locale("pt", "BR"),
    Locale("it", "IT"),
    Locale("nl", "NL"),
    Locale("pl", "PL"),
  ];

  static const List<String> _displayNames = [
    "English",
    "Türkçe",
    "Deutsch",
    "Français",
    "Español",
    "Português",
    "Italiano",
    "Nederlands",
    "Polski",
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = context.locale;
    final idx = _supportedLocales
        .indexWhere((l) => l.languageCode == currentLocale.languageCode);
    _selectedIndex = idx == -1 ? 0 : idx;
  }

  Future<void> _onConfirm() async {
    final selectedLocale = _supportedLocales[_selectedIndex];

    if (selectedLocale.languageCode == context.locale.languageCode) {
      Navigator.pop(context, false);
      return;
    }

    // GetMaterialApp builds MaterialApp with `locale: Get.locale ?? locale`,
    // and Get.locale is seeded only once in initState. Without this assignment
    // the rebuild that setLocale triggers reads a stale Get.locale and
    // MaterialApp keeps the old locale.
    Get.locale = selectedLocale;
    await context.setLocale(selectedLocale);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = MediaQuery.of(context).size.height * 0.60;

    return SizedBox(
      height: height,
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      "langSelection".tr(),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("cancel".tr()),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: _supportedLocales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) => _LanguageTile(
                    label: _displayNames[index],
                    code: _supportedLocales[index].languageCode.toUpperCase(),
                    selected: index == _selectedIndex,
                    onTap: () => setState(() => _selectedIndex = index),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onConfirm,
                  child: Text("confirm".tr()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.label,
    required this.code,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected
        ? scheme.primary.withValues(alpha: 0.10)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.4);
    final borderColor = selected
        ? scheme.primary.withValues(alpha: 0.55)
        : scheme.outlineVariant.withValues(alpha: 0.4);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary.withValues(alpha: 0.18)
                      : scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  code,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selected ? scheme.primary : scheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: selected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('on'),
                        size: 22,
                        color: scheme.primary,
                      )
                    : const SizedBox(
                        key: ValueKey('off'),
                        width: 22,
                        height: 22,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
