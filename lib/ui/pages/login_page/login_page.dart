import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_card.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/assets_keys.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/login/login_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/ui/pages/login_page/widgets/login_form.dart';
class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc,LoginState>(
      listener: (context,state){
        if(state.status==LoginStatus.waitingLogin){
          context.read<PageUtilsBloc>().lockPage();
          context.read<PageUtilsBloc>().hideSnackBar();
        }
        if(state.status==LoginStatus.errorLogin){
          context.read<PageUtilsBloc>().unlockPage();
          context.read<PageUtilsBloc>().showSnackBar(snackBar: SnackBarInfo(text: LocaleKeys.login_messages_errorLogin.tr(), snackBarType: SnackBarType.error));
        }

        if(state.status==LoginStatus.successLogin){
          context.read<PageUtilsBloc>().unlockPage();
          context.read<AuthBloc>().verify();
        }
      },
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
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.all(16),
                            child: const FittedBox(
                                fit: BoxFit.fill,
                                child: Icon(IziIcons.izi,color: IziColors.primary)
                            )
                        ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 500),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 96,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, bottom: 16),
                                child: IziCard(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 30),
                                  child: LoginForm(
                                        state: state

                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 20,
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
}
