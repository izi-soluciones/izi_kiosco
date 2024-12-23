import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/ui/general/izi_screen_inactive.dart';
import 'package:izi_kiosco/ui/modals/warning_config_modal.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_card.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_invoice.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_order_complete.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_order_error.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_qr.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_selection.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_shimmer_payment_method.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';

class PaymentPage extends StatelessWidget {
  final PageController _pageController = PageController(initialPage: 0);
  PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentBloc, PaymentState>(
      listener: (context, state) {
        if (state.step != _pageController.page) {
          _pageController.jumpToPage(state.step);
        }


        if(state.status == PaymentStatus.errorCashRegisters){
          CustomAlerts.defaultAlert(context: context,dismissible: true, child: WarningConfigModal(
              title: LocaleKeys.warningCashRegisters_title.tr(),
              description: LocaleKeys.warningCashRegisters_description.tr()
          )).then((value){
            context.read<PageUtilsBloc>().closeScreenActive();
            context.read<PaymentBloc>().closeScreenActive();
            context.read<PaymentBloc>().cancelSimphony(context.read<AuthBloc>().state);
            GoRouter.of(context).goNamed(RoutesKeys.home);
          });
        }
        if(state.status == PaymentStatus.errorActivity){
          CustomAlerts.defaultAlert(context: context,dismissible: true, child: WarningConfigModal(
              title: LocaleKeys.warningActivity_title.tr(),
              description: LocaleKeys.warningActivity_description.tr()
          )).then((value){
            context.read<PageUtilsBloc>().closeScreenActive();
            context.read<PaymentBloc>().closeScreenActive();
            context.read<PaymentBloc>().cancelSimphony(context.read<AuthBloc>().state);
            GoRouter.of(context).goNamed(RoutesKeys.home);
          });
        }


        if(state.status== PaymentStatus.cardError){
          context.read<PageUtilsBloc>().closeLoading();
          context.read<PaymentBloc>().initScreenActiveInvoiced();
          context.read<PageUtilsBloc>().showSnackBar(
              snackBar: SnackBarInfo(
                  text: LocaleKeys.payment_messages_errorCard.tr(),
                  snackBarType: SnackBarType.error));
        }
        if (state.status == PaymentStatus.errorGet || state.status == PaymentStatus.markCreateError || state.status== PaymentStatus.errorInvoiced || state.status == PaymentStatus.errorAnnulled) {

          context.read<PageUtilsBloc>().unlockPage();
          context.read<PageUtilsBloc>().closeLoading();
          context.read<PageUtilsBloc>().closeScreenActive();
          context.read<PaymentBloc>().closeScreenActive();
          if(GoRouter.of(context).canPop()){
            GoRouter.of(context).pop();
          }else{
            context.read<PaymentBloc>().cancelSimphony(context.read<AuthBloc>().state);
            GoRouter.of(context).goNamed(RoutesKeys.home);
          }
          context.read<PageUtilsBloc>().showSnackBar(
              snackBar: SnackBarInfo(
                  text: state.errorDescription ??
                      (state.status == PaymentStatus.qrError?
                      LocaleKeys.payment_messages_errorQR.tr():
                      state.status == PaymentStatus.cardError?
                      LocaleKeys.payment_messages_errorCard.tr():
                      LocaleKeys.payment_messages_errorGet.tr()),
                  snackBarType: SnackBarType.error));

        }
        if(state.status == PaymentStatus.processingInvoice){
          context.read<PageUtilsBloc>().closeScreenActive();
          context.read<PaymentBloc>().closeScreenActive();
          context.read<PageUtilsBloc>().showLoading(LocaleKeys.payment_messages_processingInvoice.tr());
        }
        if(state.status == PaymentStatus.processingOrder){
          context.read<PageUtilsBloc>().closeScreenActive();
          context.read<PaymentBloc>().closeScreenActive();
          context.read<PageUtilsBloc>().showLoading(LocaleKeys.payment_messages_processingOrder.tr());
        }
        if(state.status== PaymentStatus.paymentProcessed || state.status== PaymentStatus.cardProcessed){
          context.read<PageUtilsBloc>().closeLoading();
        }
        if(state.status == PaymentStatus.successInvoice){
          GoRouter.of(context).pushNamed(RoutesKeys.home);
        }
      },
      builder: (context, state) {
        return Listener(
          onPointerDown: (event) {
            context.read<PaymentBloc>().updateScreenActive();
          },
          child: Stack(
            children: [
              Positioned.fill(
                child: PageView(
                  physics: const NeverScrollableScrollPhysics(),
                  controller: _pageController,

                  children: [
                    //0
                    const PaymentShimmerPaymentMethod(),
                    //1
                    PaymentPageSelection(state: state),
                    //2
                    PaymentPageInvoice(state: state),
                    //3
                    PaymentPageQR(state: state),
                    //4
                    PaymentPageCard(state: state),
                    //5
                    PaymentPageOrderComplete(state: state,),
                    //6
                    const PaymentPageOrderError(),
                  ],
                ),
              ),
              if(!state.screenActive)
                const Positioned.fill(child: IziScreenInactive(cancelSimphony: true))
            ],
          ),
        );
      },
    );
  }
}
