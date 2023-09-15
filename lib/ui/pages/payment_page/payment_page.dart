import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/molecules/izi_snack_bar.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/domain/blocs/order_list/order_list_bloc.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';
import 'package:izi_kiosco/domain/blocs/payment/payment_bloc.dart';
import 'package:izi_kiosco/domain/blocs/tables/tables_bloc.dart';
import 'package:izi_kiosco/ui/modals/warning_config_modal.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_card.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_cash.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_invoice.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_payment_method.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_qr.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_resume.dart';
import 'package:izi_kiosco/ui/pages/payment_page/views/payment_page_split_payment.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_shimmer_payment_method.dart';
import 'package:izi_kiosco/ui/pages/payment_page/widgets/payment_shimmer_resume.dart';
import 'package:izi_kiosco/ui/utils/custom_alerts.dart';
import 'package:izi_kiosco/ui/utils/responsive_utils.dart';
import 'package:izi_kiosco/ui/utils/row_container.dart';

class PaymentPage extends StatelessWidget {
  final PageController _pageController = PageController(initialPage: 5);
  PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ru = ResponsiveUtils(context);
    final authState = context.read<AuthBloc>().state;
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
            GoRouter.of(context).goNamed(RoutesKeys.home);
          });
        }


        if (state.status == PaymentStatus.errorGet || state.status == PaymentStatus.errorInvoice || state.status== PaymentStatus.errorInvoiced || state.status == PaymentStatus.errorAnnulled) {
          context.read<PageUtilsBloc>().unlockPage();
          if(GoRouter.of(context).canPop()){
            GoRouter.of(context).pop();
          }else{
            GoRouter.of(context).goNamed(RoutesKeys.order);
          }
          context.read<PageUtilsBloc>().showSnackBar(
              snackBar: SnackBarInfo(
                  text: state.errorDescription ??
                      (state.status== PaymentStatus.errorInvoiced?
                      LocaleKeys.payment_messages_errorInvoiced.tr():
                      state.status== PaymentStatus.errorAnnulled?
                      LocaleKeys.payment_messages_errorAnnulled.tr():
                      LocaleKeys.payment_messages_errorGet.tr()),
                  snackBarType: SnackBarType.error));

        }
        if(state.status == PaymentStatus.successInvoice|| state.status == PaymentStatus.successPreInvoice){

          context.read<PageUtilsBloc>().unlockPage();
          context.read<OrderListBloc>().getOrders(authState: context.read<AuthBloc>().state,first: true);
          context.read<TablesBloc>().init(context.read<AuthBloc>().state);
          if(GoRouter.of(context).canPop()){
            GoRouter.of(context).pop();
          }else{
            GoRouter.of(context).goNamed(RoutesKeys.order);
          }

          context.read<PageUtilsBloc>().showSnackBar(
              snackBar: SnackBarInfo(
                  text: state.status == PaymentStatus.successInvoice?
                      LocaleKeys.payment_messages_successInvoice.tr():
                  LocaleKeys.payment_messages_successPreInvoiceCustom.tr(args: [state.casaMatriz?.config?["nombrePreFactura"]]),
                  snackBarType: SnackBarType.success));
        }
        if(state.status == PaymentStatus.successPayment){
          context.read<PageUtilsBloc>().unlockPage();
          context.read<PageUtilsBloc>().showSnackBar(
              snackBar: SnackBarInfo(
                  text: LocaleKeys.payment_messages_successPayment.tr(),
                  snackBarType: SnackBarType.success));
        }

      },
      builder: (context, state) {
        return PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _pageController,

          children: [
            //RESUME-SELECT PAYMENT = 0
            RowContainer(
              gap: 2,
              children: [
                SizedBox(
                  width: ru.gtSm() ? 400 : ru.width,
                  child: PaymentPageResume(
                    state: state,
                    authState: authState,
                  ),
                ),
                if (ru.gtSm())
                  Expanded(
                    child: PaymentPagePaymentMethod(state: state),
                  )
              ],
            ),
            //SELECT PAYMENT = 1
            PaymentPagePaymentMethod(state: state),

            //CASH = 2
            PaymentPageCash(state: state),

            //INVOICE = 3
            PaymentPageInvoice(state: state),

            //SPLIT = 4
            PaymentPageSplitPayment(state: state),

            //SHIMMER = 5
            RowContainer(
              gap: 2,
              children: [
                SizedBox(
                  width: ru.gtSm() ? 400 : ru.width,
                  child: const PaymentShimmerResume(),
                ),
                if (ru.gtSm())
                  const Expanded(
                    child: PaymentShimmerPaymentMethod(),
                  )
              ],
            ),


            //CARD DIGITS = 6
            PaymentPageCard(state: state),

            //QR PAGE = 7
            PaymentPageQr(state: state),
          ],
        );
      },
    );
  }
}
