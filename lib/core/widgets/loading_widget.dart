import 'package:flutter/material.dart';
import 'package:wallet_app/core/constants/colors.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: ColorConstants.secondaryColor,
      ),
    );
  }
}
