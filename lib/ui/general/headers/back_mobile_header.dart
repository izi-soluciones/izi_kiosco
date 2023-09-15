import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';

class BackMobileHeader extends StatelessWidget {
  final Color? background;
  final Widget title;
  final VoidCallback? onBack;
  const BackMobileHeader(
      {super.key, required this.title, this.onBack, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
        color: background,
        width: double.infinity,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(right: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            onBack != null
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                            padding: EdgeInsets.only(
                                left: 16, top: 14,right: 8,bottom: 14),
                            child: Icon(
                              IziIcons.leftB,
                              size: 25,
                            )),
                        onTap: () {
                          onBack!();
                        }),
                  )
                : const SizedBox(
                    width: 16,
                  ),
            Expanded(
                child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: title,
            ))
          ],
        ));
  }
}
