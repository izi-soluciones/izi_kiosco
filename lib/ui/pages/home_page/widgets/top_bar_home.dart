import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:izi_design_system/tokens/izi_icons.dart';
import 'package:izi_kiosco/app/values/routes_keys.dart';
import 'package:izi_kiosco/domain/blocs/auth/auth_bloc.dart';
import 'package:izi_kiosco/ui/general/user_button.dart';
class TopBarHome extends StatelessWidget {
  const TopBarHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
              onTap: () {
                Scaffold.of(context).openDrawer();
              },
              child: const Icon(IziIcons.menu,size: 32,)
          ),
          UserButton(
              user: context.read<AuthBloc>().state.currentUser?.nombres??"",
              onPressed: (tap){
                GoRouter.of(context).goNamed(RoutesKeys.userInformation);
              })
        ],
      ),
    );
  }
}
