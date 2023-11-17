import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/atoms/izi_typography.dart';
import 'package:izi_design_system/molecules/izi_btn.dart';
import 'package:izi_design_system/tokens/colors.dart';
import 'package:izi_design_system/tokens/types.dart';
import 'package:izi_kiosco/data/local/local_storage_card_errors.dart';
import 'package:izi_kiosco/domain/models/card_payment.dart';
class ErrorPaymentPage extends StatefulWidget {
  const ErrorPaymentPage({super.key});

  @override
  State<ErrorPaymentPage> createState() => _ErrorPaymentPageState();
}

class _ErrorPaymentPageState extends State<ErrorPaymentPage> {
  List<CardPayment> list=[];
  @override
  void initState() {
    LocalStorageCardErrors.getErrors().then((value) {
      for(var e in value){
        list.add(CardPayment.fromJsonStorage(jsonDecode(e)));
      }
      list = list.reversed.toList();
      setState(() {

      });
    });
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child:IziText.titleSmall(color: IziColors.dark, text: "Nº"),
                    ),
                    Expanded(
                      flex: 2,
                      child:IziText.titleSmall(color: IziColors.dark, text: "Respuesta"),
                    ),
                    Expanded(
                      child:IziText.titleSmall(color: IziColors.dark, text: "Fecha"),
                    ),
                    Expanded(
                      flex: 2,
                      child:IziText.titleSmall(color: IziColors.dark, text: "Tarjeta (U. 4 digitos)"),
                    )
                  ],
                ),
                const SizedBox(height: 20,),
                ...list.asMap().entries.map((e) {
                  return
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child:IziText.titleSmall(color: IziColors.dark, text: (e.key+1).toString()),
                          ),
                          Expanded(
                            flex: 2,
                            child:IziText.titleSmall(color: IziColors.dark, text: e.value.response),
                          ),
                          Expanded(
                            child:IziText.titleSmall(color: IziColors.dark, text: "${e.value.date} ${e.value.hour}"),
                          ),
                          Expanded(
                            flex: 2,
                            child:IziText.titleSmall(color: IziColors.dark, text: (e.value.cardNumber?.length ?? 0)>4?e.value.cardNumber!.substring(e.value.cardNumber!.length-4,e.value.cardNumber!.length):""),
                          )
                        ],
                      ),
                    );
                })
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(32),
              child: IziBtn(
                  buttonText: "Cancelar",
                  buttonType: ButtonType.primary,
                  buttonSize: ButtonSize.medium,
                  buttonOnPressed: (){
                    GoRouter.of(context).pop();
                  }
              ),
            )
          ],
        )
      ],
    );
  }
}
