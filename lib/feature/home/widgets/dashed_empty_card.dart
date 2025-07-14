import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wallet_app/feature/home/bloc/home_bloc.dart';
import 'package:sizer/sizer.dart';

class DashedEmptyCard extends StatelessWidget {
  final route;
  final text;
  const DashedEmptyCard({
    Key? key,
    required this.route,
    required this.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route).then(
        (value) => BlocProvider.of<HomeBloc>(context).add(
          LoadHomeContentEvent(),
        ),
      ),
      child: DottedBorder(
          strokeCap: StrokeCap.round,
          color: Colors.white,
          dashPattern: const [12, 4],
          radius: const Radius.circular(15),
          child: SizedBox(
            width: 90.w,
            height: 28.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 20.sp,
                ),
                Text(text,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp))
              ],
            ),
          )),
    );
  }
}
