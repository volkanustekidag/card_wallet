import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

Future<void> showLangChoseeBottomSheet(BuildContext context) async {
  showModalBottomSheet(
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
  late Locale _currentLocale;

  final List<Locale> supportedLocales = [
    const Locale("en", "US"),
    const Locale("tr", "TR"),
  ];

  final List<String> displayNames = [
    "English",
    "Türkçe",
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _currentLocale = context.locale;

    _selectedIndex = supportedLocales.indexWhere((locale) =>
        locale.languageCode == _currentLocale.languageCode &&
        locale.countryCode == _currentLocale.countryCode);
  }

  void _onConfirm() {
    final selectedLocale = supportedLocales[_selectedIndex];
    if (selectedLocale != context.locale) {
      context.setLocale(selectedLocale);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Dil Seçimi", style: Theme.of(context).textTheme.titleLarge),
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
                child: const Text("İptal"),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _onConfirm,
                child: const Text("Onayla"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
