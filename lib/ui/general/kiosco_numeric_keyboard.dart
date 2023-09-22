import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:izi_design_system/tokens/colors.dart';

class KioscoNumericKeyboard extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onDone;
  final VoidCallback onChanged;
  const KioscoNumericKeyboard({super.key,required this.controller,required this.onDone,required this.onChanged});


  @override
  Widget build(BuildContext context) {
    return Material(
      color: IziColors.lightGrey,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: IziColors.grey25,width: 1)
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 300
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                    children: [
                      Expanded(child: _numericButton(1)),
                      Expanded(child:_numericButton(2)),
                      Expanded(child:_numericButton(3)),
                    ],
                  ),
                    Row(
                      children: [
                        Expanded(child: _numericButton(4)),
                        Expanded(child:_numericButton(5)),
                        Expanded(child:_numericButton(6)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _numericButton(7)),
                        Expanded(child:_numericButton(8)),
                        Expanded(child:_numericButton(9)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Expanded(child: SizedBox.shrink()),
                        Expanded(child: _numericButton(0)),
                        const Expanded(child: SizedBox.shrink()),
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _deleteWidget(),
                    _doneWidget()
                  ],
                ),
              )

            ],
          ),
        ),
      ),
    );
  }
  Widget _doneWidget(){
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: (){
            onDone();
          },
          child: Ink(
            decoration: BoxDecoration(
                color: IziColors.primary,
                borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
                padding: EdgeInsets.all(16),
                child: FittedBox(
                  fit: BoxFit.fitWidth,
                  child: Icon(Icons.subdirectory_arrow_left,color: IziColors.white,),
                )
            ),
          ),
        ),
      ),
    );
  }
  Widget _deleteWidget(){
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: (){
            if (controller.text.isNotEmpty) {
              controller.text = controller.text.substring(0, controller.text.length - 1);
            }
            onChanged();
          },
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: FittedBox(
              child: Icon(Icons.backspace_outlined,color: IziColors.darkGrey,),
            )
          ),
        ),
      ),
    );
  }
  Widget _numericButton(int number){
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: InkWell(
          onTap: (){
            controller.text=controller.text+=number.toString();
            onChanged();
          },
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              color: IziColors.grey25,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AutoSizeText(
                number.toString(),
                style: const TextStyle(fontSize: 100,color: IziColors.darkGrey,fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
                maxLines: 1,
                maxFontSize: 100,
                minFontSize: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
