import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:izi_kiosco/domain/blocs/page_utils/page_utils_bloc.dart';

import '../../helpers/mocks.dart';

void main() {
  late MockBusinessRepository businessRepository;

  setUp(() {
    businessRepository = MockBusinessRepository();
  });

  PageUtilsBloc build() => PageUtilsBloc(businessRepository);

  blocTest<PageUtilsBloc, PageUtilsState>(
    'lockPage sets lock true',
    build: build,
    act: (bloc) => bloc.lockPage(),
    expect: () =>
        [isA<PageUtilsState>().having((s) => s.lock, 'lock', true)],
  );

  blocTest<PageUtilsBloc, PageUtilsState>(
    'unlockPage sets lock false',
    build: build,
    seed: () => build().state.copyWith(lock: true),
    act: (bloc) => bloc.unlockPage(),
    expect: () =>
        [isA<PageUtilsState>().having((s) => s.lock, 'lock', false)],
  );

  blocTest<PageUtilsBloc, PageUtilsState>(
    'changeLocation updates currentLocation',
    build: build,
    act: (bloc) => bloc.changeLocation(location: '/home'),
    expect: () => [
      isA<PageUtilsState>()
          .having((s) => s.currentLocation, 'location', '/home')
    ],
  );

  blocTest<PageUtilsBloc, PageUtilsState>(
    'showLoading then closeLoading sets and clears the title',
    build: build,
    act: (bloc) {
      bloc.showLoading('Cargando');
      bloc.closeLoading();
    },
    expect: () => [
      isA<PageUtilsState>()
          .having((s) => s.titleLoading, 'title', 'Cargando'),
      isA<PageUtilsState>().having((s) => s.titleLoading, 'title', isNull),
    ],
  );

  blocTest<PageUtilsBloc, PageUtilsState>(
    'changeSubmenuStatus toggles configurationMenuOpen',
    build: build,
    act: (bloc) => bloc.changeSubmenuStatus(configuration: true),
    expect: () => [
      isA<PageUtilsState>()
          .having((s) => s.configurationMenuOpen, 'menu', true)
    ],
  );
}
