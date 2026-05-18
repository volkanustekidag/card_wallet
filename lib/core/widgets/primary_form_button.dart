import 'package:flutter/material.dart';

/// Sticky bottom bar wrapper for add/edit screens. Sits inside
/// `Scaffold.bottomNavigationBar` so it gets pushed up by the keyboard while
/// staying pinned above the content otherwise. Adds a subtle top hairline
/// to separate from the scrolling form.
class StickyBottomBar extends StatelessWidget {
  final Widget child;
  const StickyBottomBar({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.06),
              ),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}

/// Full-width primary submit button used by add/edit card screens.
/// Disabled state and loading spinner kept consistent across credit, IBAN
/// and loyalty add flows so the bottom CTA always looks the same.
class PrimaryFormButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isBusy;

  const PrimaryFormButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isBusy = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isBusy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor:
              colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor:
              colorScheme.onSurface.withValues(alpha: 0.4),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isBusy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
