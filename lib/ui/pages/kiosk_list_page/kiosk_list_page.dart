import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/models/device.dart';
import 'package:izi_kiosco/ui/pages/kiosk_list_page/widgets/kiosk_item.dart';
class KioskListPage extends StatelessWidget {
  const KioskListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc,AuthState>(
        builder: (context,state) {
          return Stack(
            children: [
              Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Image.asset(
                        AssetsKeys.cityGraphic,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  )),
              Positioned.fill(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.all(16),
                              child: const FittedBox(
                                  fit: BoxFit.fill,
                                  child: Icon(IziIcons.izi,color: IziColors.primary)
                              )
                          ),
                          IziText.titleMedium(
                              color: IziColors.dark,
                              text: LocaleKeys.kioskList_title.tr()
                          ),
                          Expanded(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 600,
                                ),
                                child: _kioskList(state.devices),
                              ),
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            ],
          );
        }
    );
  }

  _kioskList(List<Device> devices){
    return ListView.separated(
      itemCount: devices.length+1,
      separatorBuilder: (context, index) {
        return const SizedBox(height: 16,);
      },
      padding: const EdgeInsets.symmetric(vertical: 32),
      itemBuilder: (context, index) {
        if(index == devices.length){
          if(devices.length<3){
            return IziBtn(
                buttonText: LocaleKeys.kioskList_button_add.tr(),
                buttonType: ButtonType.terciary,
                buttonSize: ButtonSize.medium,
                buttonOnPressed: (){
                  try{

                    GoRouter.of(context).goNamed(RoutesKeys.kioskNew);
                  }
                  catch(_){}
                });
          }
          else{
            return const SizedBox.shrink();
          }
        }
        return KioskItem(device: devices[index],onPressed: (){
          context.read<AuthBloc>().enableDevice(devices[index]);
        },);
      },
    );
  }
}
