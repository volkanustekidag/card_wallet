import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/controller/home_controller.dart';

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

  void _addTag(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;
    if (_tags.any((t) => t.toLowerCase() == value.toLowerCase())) return;
    setState(() {
      _tags = [..._tags, value];
    });
    _newTagController.clear();
    widget.onTagsChanged(_tags.isEmpty ? null : _tags);
  }

  void _removeTag(String tag) {
    setState(() {
      _tags = _tags.where((t) => t != tag).toList();
    });
    widget.onTagsChanged(_tags.isEmpty ? null : _tags);
  }

  /// Tags that exist on other cards but aren't already on this one. Filters
  /// by the current prefix the user has typed so the list narrows as they
  /// type. Returns empty when HomeController isn't around (e.g. unit
  /// tests) so the autocomplete row just disappears.
  List<String> _suggestions() {
    if (!Get.isRegistered<HomeController>()) return const [];
    final home = Get.find<HomeController>();
    final pool = collectAllTags(
      credits: home.creditCards,
      ibans: home.ibanCards,
    );
    final used = _tags.map((t) => t.toLowerCase()).toSet();
    final prefix = _typed.trim().toLowerCase();
    final filtered = pool.where((t) {
      if (used.contains(t.toLowerCase())) return false;
      if (prefix.isEmpty) return true;
      return t.toLowerCase().contains(prefix);
    });
    return sortedTags(filtered).take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final suggestions = _suggestions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _notesController,
          maxLines: 3,
          maxLength: 280,
          onChanged: (val) =>
              widget.onNotesChanged(val.trim().isEmpty ? null : val),
          decoration: InputDecoration(
            labelText: 'notesLabel'.tr(),
            prefixIcon: const Icon(Icons.notes_rounded, size: 20),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'tagsLabel'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final tag in _tags)
              Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => _removeTag(tag),
                backgroundColor: colorScheme.primary.withValues(alpha: 0.08),
                side: BorderSide(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _newTagController,
          onSubmitted: _addTag,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'tagsHint'.tr(),
            isDense: true,
            prefixIcon: const Icon(Icons.tag, size: 18),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _addTag(_newTagController.text),
            ),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (suggestions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in suggestions)
                ActionChip(
                  label: Text('+ $s'),
                  onPressed: () => _addTag(s),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  side: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.08),
                  ),
                  labelStyle: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.78),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
