import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_img/izi_img.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/symbiotic/symbiotic_bloc.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_header.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
class SymbioticPage extends StatelessWidget {
  const SymbioticPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ResponsiveUtils ru = ResponsiveUtils(context);
    return BlocConsumer<SymbioticBloc,SymbioticState>(
        listener: (context, state) {
          if(state is SymbioticNormalState && state.status == SymbioticStatus.paymentSuccessBack){
            Navigator.pop(context,true);
          }
        },
        builder: (context,state){
        return WillPopScope(
          onWillPop: ()async{
            if(state is SymbioticNormalState && (state.status ==  SymbioticStatus.paymentSuccess || state.status ==  SymbioticStatus.paymentSuccessBack)){
              return false;
            }
            return true;
          },
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  if(state is! SymbioticNormalState || (state.status !=  SymbioticStatus.paymentSuccess && state.status !=  SymbioticStatus.paymentSuccessBack))
                  PaymentHeader(
                    onPop: () {
                      Navigator.pop(context);
                    },
                    currency: "Bs",
                    popText: ru.gtXs() ? LocaleKeys.tapOnPhone_title.tr() : null,
                    amount: context.read<SymbioticBloc>().amount,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Builder(
                          builder: (context){
                            if(state is SymbioticNormalState){
                              /*if(state.status == SymbioticStatus.init){
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Izi Symbiotic"),
                                    IziBtn(
                                        buttonText: "Inicializar Servicio",
                                        buttonType: ButtonType.primary,
                                        buttonSize: ButtonSize.medium,
                                        buttonOnPressed: (){
                                          context.read<SymbioticBloc>().initTerminal(context.read<AuthBloc>().state);
                                        }
                                    )
                                  ],
                                );
                              }
                              else if(state.status == SymbioticStatus.initializing){
                                return const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                    Text("Initilizando POS")
                                  ],
                                );
                              }
                              else if(state.status == SymbioticStatus.terminalActive){
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Terminal ACTIVA"),
                                    IziBtn(
                                        buttonText: "Hacer transacción",
                                        buttonType: ButtonType.secondary,
                                        buttonSize: ButtonSize.medium,
                                        buttonOnPressed: (){
                                          context.read<SymbioticBloc>().makeTransaction();
                                        }
                                    )
                                  ],
                                );
                              }*/
                              if(state.status == SymbioticStatus.terminalInactive){
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IziText.titleSmall(color: IziColors.dark, text: LocaleKeys.tapOnPhone_body_noActiveTerminal.tr()),
                                    IziBtn(
                                        buttonText: LocaleKeys.tapOnPhone_buttons_activateTerminal.tr(),
                                        buttonType: ButtonType.primary,
                                        buttonSize: ButtonSize.medium,
                                        buttonOnPressed: (){
                                          context.read<SymbioticBloc>().activateTerminal();
                                        }
                                    )
                                  ],
                                );
                              }
                              else if(state.status == SymbioticStatus.activatingTerminal){
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const CircularProgressIndicator(),
                                    IziText.titleSmall(color: IziColors.dark, text: LocaleKeys.tapOnPhone_body_waitingActivate.tr()),

                                  ],
                                );
                              }
                              else if(state.status == SymbioticStatus.paymentSuccess){
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                              maxWidth: 100,
                                              maxHeight: 100
                                          ),
                                          child: const Row(
                                            children: [
                                              Expanded(
                                                child: FittedBox(
                                                    child: Icon(IziIcons.checkB,color: IziColors.secondary)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IziText.titleSmall(color: IziColors.dark, text: LocaleKeys.tapOnPhone_body_successPayment.tr()),
                                        IziText.label(color: IziColors.dark, text: LocaleKeys.tapOnPhone_labels_returning.tr(),fontWeight: FontWeight.w400),
                                        const SizedBox(height: 20),
                                        const CircularProgressIndicator(color: IziColors.dark,)
                                      ]
                                    )
                                );
                              }
                              else if(state.status == SymbioticStatus.makingPayment){
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IziText.titleSmall(color: IziColors.dark, text: LocaleKeys.tapOnPhone_body_waitingPayment.tr()),
                                    const CircularProgressIndicator(),
                                  ],
                                );
                              }
                              else{
                                return const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(),
                                  ],
                                );
                              }
                            }
                            else if (state is SymbioticErrorState){
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IziImg.alertWarning(width: 50),
                                  IziText.titleSmall(color: IziColors.dark, text: LocaleKeys.tapOnPhone_body_errorPayment.tr()),
                                    const SizedBox(height: 20,),
                                  IziBtn(
                                      buttonText: LocaleKeys.tapOnPhone_buttons_retry.tr(),
                                      buttonType: ButtonType.terciary,
                                      buttonSize: ButtonSize.medium,
                                      buttonOnPressed: (){
                                        context.read<SymbioticBloc>().makeTransaction();
                                      }
                                  )
                                ],
                              );
                            }
                            else{
                              return const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                ],
                              );
                            }

                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}
