import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/guides/presentation/models/guides_screen_state.dart';

class GuidesController extends Notifier<GuidesScreenState> {
  @override
  GuidesScreenState build() => guidesInitialState;

  void selectTab(GuideTab tab) {
    if (tab == state.selectedTab) return;
    state = GuidesScreenState(selectedTab: tab);
  }
}

final NotifierProvider<GuidesController, GuidesScreenState>
guidesControllerProvider =
    NotifierProvider.autoDispose<GuidesController, GuidesScreenState>(
      GuidesController.new,
    );
