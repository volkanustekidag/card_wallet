import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get/get.dart' hide Trans;
import 'package:get/instance_manager.dart';

Future<bool?> showLangChoseeBottomSheet(BuildContext context) async {
  return showModalBottomSheet<bool>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
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

  final List<Locale> supportedLocales = [
    const Locale("en", "US"),
    const Locale("tr", "TR"),
    const Locale("de", "DE"),
    const Locale("fr", "FR"),
  ];

  final List<String> displayNames = [
    "English",
    "Türkçe",
    "Deutsch",
    "Français",
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = 0; // Default to English initially
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Find current language index - safe to access context here
    final currentLocale = context.locale;
    _selectedIndex = supportedLocales.indexWhere(
        (locale) => locale.languageCode == currentLocale.languageCode);

    if (_selectedIndex == -1) {
      _selectedIndex = 0; // Default to English
    }

    print('Current locale: $currentLocale, Selected index: $_selectedIndex');
  }

  void _onConfirm() async {
    final selectedLocale = supportedLocales[_selectedIndex];

    if (selectedLocale.languageCode != context.locale.languageCode) {
      await context.setLocale(selectedLocale);
      Get.updateLocale(selectedLocale);
      Navigator.pop(context, true);
    } else {
      Navigator.pop(context, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("langSelection".tr(),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...List.generate(supportedLocales.length, (index) {
            return RadioListTile<int>(
              value: index,
              groupValue: _selectedIndex,
              title: Text(displayNames[index]),
              onChanged: (int? value) {
                if (value != null) {
                  setState(() {
                    _selectedIndex = value;
                  });
                }
              },
            );
          }),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("cancel".tr()),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onConfirm,
                child: Text("confirm".tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
