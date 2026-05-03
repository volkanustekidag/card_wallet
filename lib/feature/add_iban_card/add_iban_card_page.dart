import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:camera/camera.dart';
import 'package:wallet_app/core/domain/models/iban_card_model/iban_card.dart';
import 'package:wallet_app/core/widgets/add_iban_card_widget.dart';
import 'package:wallet_app/feature/add_iban_card/controller/add_iban_card_controller.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/add_iban_app_bar.dart';
import 'package:wallet_app/feature/add_iban_card/widgets/iban_text_forms.dart';

class AddIbanCardPage extends StatefulWidget {
  final IbanCard? ibanCard;

  const AddIbanCardPage({Key? key, this.ibanCard}) : super(key: key);

  @override
  State<AddIbanCardPage> createState() => _AddIbanCardPageState();
}

class _AddIbanCardPageState extends State<AddIbanCardPage> {
  late TextEditingController _ibanController;
  late FocusNode _ibanFocusNode;
  late final AddIbanCardController _controller =
      Get.find<AddIbanCardController>();
  late final ScrollController _scrollController;
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    _initCameras();
    _ibanController = TextEditingController();
    _ibanFocusNode = FocusNode();
    _scrollController = ScrollController();

    if (widget.ibanCard != null) {
      _controller.initializeForEdit(widget.ibanCard!);
    } else {
      _controller.initializeForCreate();
    }

    // Auto-expand the preview when the IBAN field gains focus — that's
    // the one whose typing actually lands on the visible card, and it
    // sits at the top of the form so it fits above the keyboard while
    // the card is full-size. Other fields (holder/bank/swift) live
    // further down: auto-expanding for them just causes a flicker when
    // Flutter's ensureVisible scrolls them back above the keyboard.
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChange);
    _scrollController.dispose();
    _ibanController.dispose();
    _ibanFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final node = FocusManager.instance.primaryFocus;
    if (node == null || !node.hasFocus) return;
    if (node != _ibanFocusNode) return;
    _expandPreview();
  }

  void _expandPreview() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 0.5) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  /// Tap on the collapsed pill: dismiss the keyboard and animate the
  /// preview back to its full-size state. Lets the user "open" the card
  /// to verify what they've entered without scrolling all the way up.
  void _handleCollapsedTap() {
    FocusScope.of(context).unfocus();
    _expandPreview();
  }

  void _initCameras() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final availableCams = await availableCameras();
      if (mounted) {
        setState(() {
          cameras = availableCams;
        });
      }
      debugPrint('✅ Loaded ${cameras.length} cameras');
    } catch (e) {
      debugPrint('❌ Camera initialization error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Card horizontal margin (12 each side) matches the original layout.
    final cardWidth = mq.size.width - 24;
    final cardHeight = cardWidth / 1.586;
    // Header extents include 8px top/bottom breathing room around the card.
    final maxExt = cardHeight + 16;
    const minExt = 80.0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AddIbanAppBar(ibanCard: widget.ibanCard),
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _IbanPreviewHeaderDelegate(
              minExt: minExt,
              maxExt: maxExt,
              onCollapsedTap: _handleCollapsedTap,
              builder: (t) => Obx(() => AddIbanCardWidget(
                    ibanCard: _controller.currentCard.value,
                    collapse: t,
                  )),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              24,
              16,
              24,
              32 + mq.viewInsets.bottom,
            ),
            sliver: SliverToBoxAdapter(
              child: IbanTextFieldForms(
                ibanController: _ibanController,
                focusNode: _ibanFocusNode,
                cameras: cameras,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned header that crossfades [AddIbanCardWidget] from full preview to
/// compact pill as the user scrolls. The shrink fraction is computed from
/// the sliver's [shrinkOffset] and forwarded to the card so it can swap
/// inner content (full IBAN/holder/swift → bank + last-4 + IBAN tag).
class _IbanPreviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExt;
  final double maxExt;
  final VoidCallback onCollapsedTap;
  final Widget Function(double collapse) builder;

  _IbanPreviewHeaderDelegate({
    required this.minExt,
    required this.maxExt,
    required this.onCollapsedTap,
    required this.builder,
  });

  @override
  double get minExtent => minExt;

  @override
  double get maxExtent => maxExt;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final range = (maxExt - minExt).clamp(1.0, double.infinity);
    final t = (shrinkOffset / range).clamp(0.0, 1.0);
    // Once the card is mostly collapsed, taps "open" it: dismiss the
    // keyboard and animate the preview back to full size. Above this
    // threshold the card is just a static visual — taps fall through
    // (via opaque hit-testing on the surrounding scrollable).
    final tappable = t > 0.5;
    return Container(
      // Match the scaffold's background — both add pages set it to
      // `colorScheme.surface`, which differs from `scaffoldBackgroundColor`
      // (especially in dark mode) so using the latter leaves a visible
      // darker patch behind the pinned card preview.
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: tappable ? onCollapsedTap : null,
        child: builder(t),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _IbanPreviewHeaderDelegate oldDelegate) {
    return oldDelegate.minExt != minExt ||
        oldDelegate.maxExt != maxExt ||
        oldDelegate.onCollapsedTap != onCollapsedTap;
  }
}
