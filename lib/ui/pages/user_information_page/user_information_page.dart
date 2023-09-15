import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_link.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/ui/general/headers/back_mobile_header.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';

class UserInformationPage extends StatelessWidget {
  const UserInformationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    return BlocBuilder<AuthBloc,AuthState>(
        builder: (context,state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if(ru.isXs())
                BackMobileHeader(
                    title: IziText.title(color: IziColors.dark, text: LocaleKeys.user_information_title.tr()),
                    onBack: (){
                      GoRouter.of(context).goNamed(RoutesKeys.home);
                    }
                ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IziText.body(text: LocaleKeys.user_information_body_user_label.tr(), color:IziColors.grey, fontWeight: FontWeight.w500),
                    const SizedBox(height: 4,),
                    IziText.body(text: "${state.currentUser?.nombres??""} ${state.currentUser?.apPaterno??""} ${state.currentUser?.apMaterno??""}" , color:IziColors.dark, fontWeight: FontWeight.w500),
                    const SizedBox(height: 16,),
                    IziText.body(text: LocaleKeys.user_information_body_email_label.tr(), color:IziColors.grey, fontWeight: FontWeight.w500),
                    const SizedBox(height: 4,),
                    IziText.body(text: state.currentUser?.correoElectronico??"" , color:IziColors.dark, fontWeight: FontWeight.w500),
                  ],
                ),
              ),
              const Divider(color: IziColors.grey35,thickness: 1,height: 1,),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IziLink(
                        linkText: LocaleKeys.user_information_links_sign_out.tr(),
                        linkOnPressed: (){
                          if(ru.gtMd()){
                            Navigator.pop(context);
                          }
                          context.read<AuthBloc>().logout();
                        },
                        linkColor: IziColors.red
                    )
                  ],
                ),
              )

            ],
          );
        }
    );
}
}
