import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/services/ui_prefs.dart';
import 'package:wallet_app/core/utils/tag_index.dart';
import 'package:wallet_app/feature/home/wallet_home.dart';
import 'package:wallet_app/feature/home/widgets/sections/wallet_item.dart';
import 'package:wallet_app/ui/card/wallet_card_faces.dart';
import 'package:wallet_app/ui/components/cw_button.dart';
import 'package:wallet_app/ui/components/cw_list.dart';
import 'package:wallet_app/ui/components/cw_misc.dart';
import 'package:wallet_app/ui/components/cw_top_bar.dart';
import 'package:wallet_app/ui/cw_icons.dart';
import 'package:wallet_app/ui/tokens.dart';
import 'package:wallet_app/ui/typography.dart';

/// Folders under the segments: favourites and the user's own tags. Tap one
/// to narrow the wallet to it, tap it again (or its ×) to show everything.
class FolderRow extends StatelessWidget {
  final List<String> folders;
  final String? selected;
  final ValueChanged<String?> onChanged;

  const FolderRow({
    super.key,
    required this.folders,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return SizedBox(
      height: 46,
      child: ListView.separated(
        key: const ValueKey('homeFolders'),
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.fromLTRB(CwSpace.gutter, 10, CwSpace.gutter, 0),
        itemCount: folders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final f = folders[i];
          final on = f == selected;
          final fav = f == kFavoriteTag;
          final fg = on ? c.bg : c.ink;
          return Semantics(
            button: true,
            selected: on,
            child: Material(
              key: ValueKey('folder_$f'),
              color: on ? c.ink : c.surface,
              shape: const StadiumBorder(),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(on ? null : f);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CwIcon(fav ? CwIcons.starFill : CwIcons.folder,
                          size: 15, color: fav && !on ? c.warn : fg),
                      const SizedBox(width: 6),
                      Text(
                        fav ? 'filterFavorites'.tr() : f,
                        style: CwType.footnote
                            .copyWith(color: fg, fontWeight: FontWeight.w600),
                      ),
                      if (on) ...[
                        const SizedBox(width: 6),
                        CwIcon(CwIcons.close, size: 13, color: fg),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Small square button on the count line that opens the order sheet.
class SortButton extends StatelessWidget {
  final VoidCallback onTap;
  const SortButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return Semantics(
      button: true,
      label: 'cwSortTitle'.tr(),
      excludeSemantics: true,
      child: Material(
        key: const ValueKey('homeSortButton'),
        color: c.surface2,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 34,
            height: 30,
            child: Center(child: CwIcon(CwIcons.sort, size: 16, color: c.ink)),
          ),
        ),
      ),
    );
  }
}

/// Smart / name / my order, and the way into reordering.
Future<void> showHomeSortSheet(BuildContext context,
    {required List<WalletItem> items}) {
  final prefs = UiPrefs.instance;
  return showCwSheet<void>(
    context,
    builder: (sheet) {
      final c = CwColors.of(sheet);
      return SafeArea(
        top: false,
        child: Obx(() {
          final current = HomeSort.parse(prefs.homeSort.value);
          Widget option(HomeSort s, String title, String? sub) => CwRow(
                key: ValueKey('sort_${s.name}'),
                title: title,
                subtitle: sub,
                trailing: current == s
                    ? CwIcon(CwIcons.check, color: c.accent)
                    : const SizedBox(width: 24),
                onTap: () {
                  HapticFeedback.selectionClick();
                  prefs.setHomeSort(s.name);
                  if (s == HomeSort.manual && prefs.manualOrder.isEmpty) {
                    Navigator.pop(sheet);
                    openReorderCards(context, items: items);
                  } else {
                    Navigator.pop(sheet);
                  }
                },
              );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 4, 22, 10),
                child: Text('cwSortTitle'.tr(),
                    style: CwType.title.copyWith(color: c.ink, fontSize: 20)),
              ),
              CwGroup(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  option(HomeSort.smart, 'cwSortSmart'.tr(),
                      'cwSortSmartSub'.tr()),
                  option(HomeSort.name, 'sortNameAsc'.tr(), null),
                  option(HomeSort.manual, 'cwSortManual'.tr(),
                      'cwSortManualSub'.tr()),
                ],
              ),
              CwGroup(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  CwRow(
                    key: const ValueKey('sortEditOrder'),
                    leading: CwIcon(CwIcons.grip, color: c.ink),
                    title: 'cwEditOrder'.tr(),
                    chevron: true,
                    onTap: () {
                      Navigator.pop(sheet);
                      openReorderCards(context, items: items);
                    },
                  ),
                ],
              ),
            ],
          );
        }),
      );
    },
  );
}

Future<void> openReorderCards(BuildContext context,
    {required List<WalletItem> items}) {
  return Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => ReorderCardsPage(items: items),
  ));
}

/// Drag cards into the user's own order. Saves as it goes and switches
/// Home to "My order".
class ReorderCardsPage extends StatefulWidget {
  final List<WalletItem> items;
  const ReorderCardsPage({super.key, required this.items});

  @override
  State<ReorderCardsPage> createState() => _ReorderCardsPageState();
}

class _ReorderCardsPageState extends State<ReorderCardsPage> {
  late final List<WalletItem> _order = () {
    final prefs = UiPrefs.instance;
    // Start from what Home shows now, so the first drag moves one card.
    return stackOrder(
      widget.items,
      HomeFilter.all,
      sort: HomeSort.parse(prefs.homeSort.value),
      manualOrder: prefs.manualOrder.toList(),
    );
  }();

  void _save() {
    UiPrefs.instance.setManualOrder([for (final it in _order) it.heroTag]);
    if (UiPrefs.instance.homeSort.value != HomeSort.manual.name) {
      UiPrefs.instance.setHomeSort(HomeSort.manual.name);
    }
  }

  @override
  void initState() {
    super.initState();
    // After the first frame: saving rebuilds Home, which can't happen
    // while this page is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _save();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = CwColors.of(context);
    return CwPageStyle(
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: CwScrollEdge(
            bar: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 6),
              child: Row(
                children: [
                  CwCircleButton(
                    CwIcons.back,
                    onPressed: () => Navigator.of(context).maybePop(),
                    semanticLabel:
                        MaterialLocalizations.of(context).backButtonTooltip,
                  ),
                  Expanded(
                    child: Text('cwEditOrder'.tr(),
                        textAlign: TextAlign.center,
                        style: CwType.headline.copyWith(color: c.ink)),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),
            body: ReorderableListView.builder(
              key: const ValueKey('reorderList'),
              padding: EdgeInsets.fromLTRB(CwSpace.gutter, 4, CwSpace.gutter,
                  24 + MediaQuery.paddingOf(context).bottom),
              header: Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
                child: Text('cwReorderHint'.tr(),
                    style: CwType.footnote.copyWith(color: c.mute)),
              ),
              buildDefaultDragHandles: false,
              proxyDecorator: (child, _, __) => Material(
                color: Colors.transparent,
                elevation: 6,
                borderRadius: BorderRadius.circular(CwRadius.m),
                child: child,
              ),
              itemCount: _order.length,
              onReorder: (from, to) {
                HapticFeedback.selectionClick();
                setState(() {
                  if (to > from) to -= 1;
                  _order.insert(to, _order.removeAt(from));
                });
                _save();
              },
              itemBuilder: (context, i) {
                final it = _order[i];
                return Padding(
                  key: ValueKey(it.heroTag),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(CwRadius.m),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                      child: Row(
                        children: [
                          CardThumb(item: it, width: 52),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(titleForItem(it),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: CwType.headline
                                        .copyWith(color: c.ink, fontSize: 16)),
                                Text(typeLabelFor(it.kind),
                                    style: CwType.footnote
                                        .copyWith(color: c.mute)),
                              ],
                            ),
                          ),
                          ReorderableDragStartListener(
                            index: i,
                            child: Semantics(
                              label: 'cwReorderHint'.tr(),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: CwIcon(CwIcons.grip, color: c.mute),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
