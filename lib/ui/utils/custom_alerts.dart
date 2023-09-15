import 'package:flutter/material.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/hoverStates/on_hover.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';


class TapMenuItem{
  final String name;
  final dynamic value;
  final Color? color;
  final FontWeight? fontWeight;

  TapMenuItem({
      required this.name,
      required this.value,
      this.color,
      this.fontWeight
});
}
class CustomAlerts {


  static Future<dynamic> showTapMenu(Offset offset,List<TapMenuItem> values,BuildContext context,{double? minWidth}){
    return showMenu(
        context: context,
        items: values.asMap().entries.map((e) {
          return PopupMenuItem(
              value: e.value.value,
              height: 1,
              padding: EdgeInsets.zero,
              child: OnHover(
                builder: (isHovered) {
                  return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(bottom:  12,top: 12,left: 20,right: 20),
                      decoration: BoxDecoration(
                        color: isHovered?IziColors.lightGrey:null,
                          border: e.key==values.length-1?null:const Border(
                              bottom: BorderSide(
                                  color: IziColors.lightGrey,
                                  width: 1.5
                              )
                          )
                      ),
                      child: IziText.body(color: e.value.color??IziColors.darkGrey, text: e.value.name, fontWeight: e.value.fontWeight??FontWeight.w500)
                  );
                },
              )

          );
        }).toList(),
        constraints: BoxConstraints(
            minWidth: minWidth ?? 320,
            minHeight: 10,
        ),
        color: IziColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        position: RelativeRect.fromLTRB(
            offset.dx, offset.dy, offset.dx, offset.dy),
        useRootNavigator: true
    );
  }
  static alertWithPositionWidget(

      Offset position, BuildContext context, Widget widget,Function(dynamic) callback,{double? maxHeight}) {

    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: true,
        builder: (context) {
          final ru = ResponsiveUtils(context);
          return Stack(
            children: [
              Positioned(
                left: position.dx+320 >ru.width?null:position.dx,
                right: position.dx+320 <=ru.width?null:ru.width-position.dx,
                top: position.dy+350 > ru.height?null:position.dy,
                bottom: position.dy+350 <= ru.height?null:10,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: 320 > position.dx? position.dx:320,
                    maxHeight:(maxHeight ?? 350) > ru.height+20?ru.height-20:(maxHeight ?? 350)
                  ),
                  child: Material(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)
                    ),
                    color: IziColors.white,
                    child: widget,
                  ))
                ),
            ],
          );
        }).then((value) => callback(value));
  }

  static alertWithLayout(
      {required context,
      required Function(dynamic) onResult,
      required bool bottomAlert,
      required Widget widget}) {
    var flagPop = false;
    if (bottomAlert) {
      showModalBottomSheet(
          context: context,
          useRootNavigator: true,
          enableDrag: false,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) {
            final size = MediaQuery.of(context).size;
            if (size.width > xs) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!flagPop) {
                  Navigator.of(context).pop();
                }
                flagPop = true;
              });
            }
            return ConstrainedBox(
              constraints:
                  BoxConstraints(maxHeight: size.height * 0.8, minHeight: 1),
              child: widget,
            );
          }).then((filters) {
        onResult(filters);
      });
    } else {
      showDialog(
          context: context,
          useSafeArea: true,
          builder: (context) {
            final size = MediaQuery.of(context).size;
            if (size.width <= xs) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!flagPop) {
                  Navigator.of(context).pop();
                }
                flagPop = true;
              });
            }
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: FractionallySizedBox(
                  heightFactor: 0.8,
                  child: Dialog(
                      insetPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: widget)),
                ),
              ),
            );
          }).then((filters) {
        onResult(filters);
      });
    }
  }

  static alertTopLeft(
      {required Widget content,
      required BuildContext context,
      bool dismissible = true}) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: dismissible,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              return dismissible;
            },
            child: LayoutBuilder(builder: (context, layout) {
              return Stack(
                children: [
                  Positioned(
                      top: 10,
                      left: 10,
                      width: 297,
                      child: Dialog(
                        insetPadding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxWidth: 297,
                              maxHeight: layout.maxHeight,
                              minWidth: 297),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: content,
                          ),
                        ),
                      ))
                ],
              );
            }),
          );
        });
  }
  static Future<dynamic> alertExpanded(
      {required Widget content,
        required BuildContext context,
        bool dismissible = true}) async{
    return showDialog(
        context: context,
        useSafeArea: true,
        barrierColor: Colors.transparent,
        barrierDismissible: dismissible,
        builder: (context) {
          final ru = ResponsiveUtils(context);
          return WillPopScope(
            onWillPop: () async {
              return dismissible;
            },
            child: Dialog(
              insetPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: ru.isXs()?BorderRadius.zero:BorderRadius.circular(12)
              ),

              child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: ru.isXs() ?double.infinity:ru.height,
                    minHeight: ru.isXs() ?ru.height:0,
                    minWidth: ru.isXs() ? ru.width : 0,
                    maxWidth: ru.isXs() ? ru.width : 550,
                  ),
                  child: ClipRRect(borderRadius: ru.isXs()?BorderRadius.zero:BorderRadius.circular(12),child: content)),
            ),
          );
        });
  }
  static alertRight(
      {required Widget content,
      required BuildContext context,
      bool dismissible = true}) {
    showDialog(
        context: context,
        useSafeArea: true,
        barrierColor: Colors.transparent,
        barrierDismissible: dismissible,
        builder: (context) {
          final ru = ResponsiveUtils(context);
          return WillPopScope(
            onWillPop: () async {
              return dismissible;
            },
            child: Stack(
              children: [
                Positioned(
                    top: 0,
                    right: 0,
                    width: ru.isXs() ? ru.width : 480,
                    child: Dialog(
                      insetPadding: EdgeInsets.zero,
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: ru.height,
                            minHeight: ru.height,
                            minWidth: ru.isXs() ? ru.width : 0,
                            maxWidth: ru.isXs() ? ru.width : 480,
                          ),
                          child: content),
                    ))
              ],
            ),
          );
        });
  }

  static alertTopRight(
      {required Widget content,
        required Offset offset,
      required BuildContext context,
      bool dismissible = true}) {

    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        barrierDismissible: dismissible,
        builder: (context) {
          final ru=ResponsiveUtils(context);
          return WillPopScope(
            onWillPop: () async {
              return dismissible;
            },
            child: Stack(
              children: [
                Positioned(
                    top: 20,
                    right: ru.width-offset.dx,
                    width: 400,
                    child: Dialog(
                      insetPadding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 450,
                            minHeight: 200,
                            maxWidth: 400,
                            minWidth: 400),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: content,
                        ),
                      ),
                    ))
              ],
            ),
          );
        });
  }

  static Future<dynamic> defaultAlert(
      {required BuildContext context,
      required Widget child,
        bool defaultScroll = true,
      EdgeInsetsGeometry? padding,
      bool dismissible = false}) async {
    final size = MediaQuery.of(context).size;
    return showDialog(
        context: context,
        barrierDismissible: dismissible,
        builder: (context) {
          return WillPopScope(
            onWillPop: () async {
              return dismissible;
            },
            child: Center(
                child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: 400,
                        maxHeight: size.height * 0.8,
                        minHeight: 0,
                        minWidth: 400),
                    child: AlertDialog(
                        insetPadding: const EdgeInsets.all(0),
                        contentPadding: padding ?? const EdgeInsets.all(24),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        backgroundColor: IziColors.lightGrey30,
                        content: SizedBox(
                          width: 800,
                          child: defaultScroll?SingleChildScrollView(child: child):child,
                        )))),
          );
        });
  }
}
