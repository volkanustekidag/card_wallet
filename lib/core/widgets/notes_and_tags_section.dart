import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Reusable Notes + Tags input. Used by both add-credit-card and
/// add-iban-card forms. Tags are entered as comma-separated values and
/// stored as a `List<String>`.
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

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.initialNotes ?? '');
    _newTagController = TextEditingController();
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
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
      ],
    );
  }
}
