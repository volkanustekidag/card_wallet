import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';
import 'package:wallet_app/ui/components/cw_field.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Reusable Notes + Tags input. Used by both add-credit-card and
/// add-iban-card forms. Tags are entered by typing and tapping +/Enter,
/// or by tapping a suggestion chip — suggestions come from every tag
/// already in use across the wallet (read off HomeController, which is
/// always alive once the user is past splash).
class NotesAndTagsSection extends StatefulWidget {
  final String? initialNotes;
  final List<String>? initialTags;
  final ValueChanged<String?> onNotesChanged;
  final ValueChanged<List<String>?> onTagsChanged;

  const NotesAndTagsSection({
    Key? key,
    required this.initialNotes,
    required this.initialTags,
    required this.onNotesChanged,
    required this.onTagsChanged,
  }) : super(key: key);

  @override
  State<NotesAndTagsSection> createState() => _NotesAndTagsSectionState();
}

class _NotesAndTagsSectionState extends State<NotesAndTagsSection> {
  late final TextEditingController _notesController;
  late final TextEditingController _newTagController;
  late List<String> _tags;
  String _typed = '';

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _newTagController = TextEditingController();
    _newTagController.addListener(() {
      final v = _newTagController.text;
      if (v != _typed) setState(() => _typed = v);
    });
    _tags = [...?widget.initialTags];
  }

  @override
  void dispose() {
    _notesController.dispose();
    _newTagController.dispose();
    super.dispose();
  }

  /// The favourite flag lives in tags but is toggled with the star, not
  /// shown as a tag; keep it out of the chips and carry it through.
  bool get _favourite => widget.initialTags?.contains(kFavoriteTag) ?? false;

  List<String> get _visible => _tags.where((t) => t != kFavoriteTag).toList();

  void _emit() {
    final out = [..._visible, if (_favourite) kFavoriteTag];
    widget.onTagsChanged(out.isEmpty ? null : out);
  }

  void _addTag(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value == kFavoriteTag) return;
    if (_tags.any((t) => t.toLowerCase() == value.toLowerCase())) return;
    setState(() {
      _tags = [..._tags, value];
    });
    _newTagController.clear();
    _emit();
  }

  void _removeTag(String tag) {
    setState(() {
      _tags = _tags.where((t) => t != tag).toList();
    });
    _emit();
  }

  List<String> _suggestions() {
    if (!Get.isRegistered<HomeController>()) return const [];
    final home = Get.find<HomeController>();
    final pool = collectAllTags(
      credits: home.creditCards,
      ibans: home.ibanCards,
      loyalties: home.loyaltyCards,
    );
    final used = _tags.map((t) => t.toLowerCase()).toSet();
    final prefix = _typed.trim().toLowerCase();
    final filtered = pool.where((t) {
      if (t == kFavoriteTag || used.contains(t.toLowerCase())) return false;
      if (prefix.isEmpty) return true;
      return t.toLowerCase().contains(prefix);
    });
    return sortedTags(filtered).take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    final suggestions = _suggestions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CwField(
          controller: _notesController,
          label: 'notesLabel'.tr(),
          maxLines: 3,
          maxLength: 280,
          onChanged: (val) =>
              widget.onNotesChanged(val.trim().isEmpty ? null : val),
        ),
        const SizedBox(height: 10),
        if (_visible.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in _visible)
                _TagChip(
                  label: '#$tag',
                  selected: true,
                  onTap: () => _removeTag(tag),
                  trailing: CwIcon(CwIcons.close, size: 12, color: c.bg),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        CwField(
          controller: _newTagController,
          label: 'tagsLabel'.tr(),
          hint: 'tagsHint'.tr(),
          icon: CwIcons.hash,
          textInputAction: TextInputAction.done,
          onSubmitted: _addTag,
          trailing: IconButton(
            tooltip: 'tagsLabel'.tr(),
            icon: CwIcon(CwIcons.plus, size: 18, color: c.accent),
            onPressed: () => _addTag(_newTagController.text),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in suggestions)
                _TagChip(label: '+ $s', onTap: () => _addTag(s)),
            ],
          ),
        ],
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;

  const _TagChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.ink : c.surface2,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: CwType.footnote.copyWith(
                    color: selected ? c.bg : c.ink,
                    fontWeight: FontWeight.w600)),
            if (trailing != null) ...[const SizedBox(width: 6), trailing!],
          ],
        ),
      ),
    );
  }
}
