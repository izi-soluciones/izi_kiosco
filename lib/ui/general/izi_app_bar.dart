import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/ui/general/user_button.dart';
import 'package:izi_kiosco/ui/pages/user_information_page/user_information_page.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';

class IziAppBar extends StatelessWidget {
  const IziAppBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthBloc>().state.currentUser;
    return Container(
      color: IziColors.lightGrey,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                    child:const Icon(IziIcons.home,size: 18
                      ,color: IziColors.dark,),
                    onTap: (){
                      GoRouter.of(context).goNamed(RoutesKeys.home);
                    }
                ),
              ),
              _buildBreadcrumbs(GoRouterState.of(context).fullPath??"", context)
            ],
          ),
          UserButton(
            user: user?.nombres ??"",
            onPressed: (details){
              CustomAlerts.alertTopRight(content: const UserInformationPage(), context: context,offset: details.globalPosition);
              },
          )
        ],
      ),

    );
  }

  Widget _buildBreadcrumbs(String location,BuildContext context){
    List<Widget> listLinks=[];
    List<String> listPath=location.split("/");
    if(listPath.isNotEmpty){
      for(int i=1;i<listPath.length;i++){
        listLinks.add(
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                  onTap: (){
                    GoRouter.of(context).goNamed(listPath[i]);
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 5,),
                      const Icon(IziIcons.right,size: 12,color: IziColors.darkGrey,),
                      const SizedBox(width: 5,),
                      IziText.body(text: "${listPath[i]}.drawer".tr(), color: IziColors.darkGrey, fontWeight: i==listPath.length-1?FontWeight.w600:FontWeight.w400)
                    ],
                  )
              ),
            )
        );
      }
    }
    return Row(
      children: listLinks,
    );
  }
}
