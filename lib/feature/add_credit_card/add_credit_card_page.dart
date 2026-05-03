import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Trans;
import 'package:wallet_app/core/domain/models/credit_card_model/credit_card.dart';
import 'package:wallet_app/core/widgets/add_credit_card_widget.dart';
import 'package:wallet_app/feature/add_credit_card/controller/add_credit_card_controller.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/add_credit_app_bar.dart';
import 'package:wallet_app/feature/add_credit_card/widgets/credit_form.dart';

class AddCreditCardPage extends StatefulWidget {
  final CreditCard? creditCard;

  const AddCreditCardPage({Key? key, this.creditCard}) : super(key: key);

  @override
  State<AddCreditCardPage> createState() => _AddCreditCardPageState();
}

class _AddCreditCardPageState extends State<AddCreditCardPage> {
  late final AddCreditCardController _controller =
      Get.find<AddCreditCardController>();
  late final ScrollController _scrollController;
  late final FocusNode _cardNumberFocusNode;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _cardNumberFocusNode = FocusNode();

    if (widget.creditCard != null) {
      _controller.initializeForEdit(widget.creditCard!);
    } else {
      _controller.initializeForCreate();
    }

    // Auto-expand the preview when the card-number field gains focus.
    // That's the field whose typing lands on the visible card and it sits
    // near the top of the form so it fits above the keyboard while the
    // card is full-size. Other fields stay at the user's scroll position.
    FocusManager.instance.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_handleFocusChange);
    _scrollController.dispose();
    _cardNumberFocusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!mounted) return;
    final node = FocusManager.instance.primaryFocus;
    if (node == null || !node.hasFocus) return;
    if (node != _cardNumberFocusNode) return;
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

  void _handleCollapsedTap() {
    FocusScope.of(context).unfocus();
    _expandPreview();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Card horizontal margin (12 each side) matches the IBAN page so the
    // two add flows feel identical.
    final cardWidth = mq.size.width - 24;
    final cardHeight = cardWidth / 1.586;
    final maxExt = cardHeight + 16;
    const minExt = 80.0;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: colorScheme.surface,
      appBar: AddCreditAppBar(creditCard: widget.creditCard),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _CreditPreviewHeaderDelegate(
                minExt: minExt,
                maxExt: maxExt,
                onCollapsedTap: _handleCollapsedTap,
                builder: (t) => Obx(() => AddCreditCardWidget(
                      creditCard: _controller.currentCard.value,
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
                child: CreditTextFieldForms(
                  cardNumberFocusNode: _cardNumberFocusNode,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pinned header that crossfades [AddCreditCardWidget] from full preview
/// to compact pill as the user scrolls. Mirrors the IBAN add page's
/// header so both flows feel the same.
class _CreditPreviewHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minExt;
  final double maxExt;
  final VoidCallback onCollapsedTap;
  final Widget Function(double collapse) builder;

  _CreditPreviewHeaderDelegate({
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
  bool shouldRebuild(covariant _CreditPreviewHeaderDelegate oldDelegate) {
    return oldDelegate.minExt != minExt ||
        oldDelegate.maxExt != maxExt ||
        oldDelegate.onCollapsedTap != onCollapsedTap;
  }
}
