import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:izi_design_system/atoms/izi_img/izi_img.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/molecules/izi_btn_link_icon.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/app/values/locale_keys.g.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';

/// What the customer chose on [CardErrorModal].
enum CardErrorChoice { retry, otherMethod }

/// A card charge that did not go through, told on the screen itself.
///
/// [pending] is a charge whose outcome is unknown: the card may have been
/// charged, so it offers no retry and sends the customer to staff.
class CardErrorModal extends StatelessWidget {
  final bool pending;
  final String? detail;
  final bool canRetry;

  const CardErrorModal({
    super.key,
    required this.pending,
    this.detail,
    this.canRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    final title = pending
        ? LocaleKeys.payment_cardError_pendingTitle.tr()
        : LocaleKeys.payment_cardError_title.tr();
    final description = pending
        ? LocaleKeys.payment_cardError_pendingDescription.tr()
        : LocaleKeys.payment_cardError_description.tr();
    return BlocListener<PageUtilsBloc, PageUtilsState>(
      // The kiosk timed out and is going home: nothing to answer anymore.
      listener: (context, state) {
        if (state.screenActive == false) Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IziImg.alertWarning(width: 72.3),
          const SizedBox(height: 24),
          IziText.titleSmall(
              text: title,
              maxLines: 5,
              mobile: true,
              textAlign: TextAlign.center,
              color: context.iziColors.dark),
          const SizedBox(height: 8),
          IziText.body(
              text: description,
              maxLines: 10,
              fontWeight: FontWeight.w400,
              textAlign: TextAlign.center,
              color: context.iziColors.darkGrey),
          if (detail != null && detail!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            IziText.body(
                text: detail!.trim(),
                maxLines: 6,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
                color: context.iziColors.dark),
          ],
          const SizedBox(height: 24),
          if (pending || !canRetry)
            IziBtn(
              buttonSize: ButtonSize.medium,
              buttonType: ButtonType.primary,
              buttonText: LocaleKeys.general_buttons_accept.tr(),
              buttonOnPressed: () =>
                  Navigator.pop(context, CardErrorChoice.otherMethod),
            )
          else ...[
            IziBtn(
              buttonSize: ButtonSize.medium,
              buttonType: ButtonType.primary,
              buttonText: LocaleKeys.payment_cardError_retry.tr(),
              buttonOnPressed: () =>
                  Navigator.pop(context, CardErrorChoice.retry),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: IziBtnLinkIcon(
                filterText: LocaleKeys.payment_cardError_otherMethod.tr(),
                color: context.iziColors.grey,
                icon: IziIcons.leftB,
                filterTextOnPress: () =>
                    Navigator.pop(context, CardErrorChoice.otherMethod),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
