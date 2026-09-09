import 'package:look_atlas/features/calendar/domain/entities/calendar_models.dart';
import 'package:look_atlas/features/calendar/presentation/controllers/calendar_session.dart';

/// Immutable provider snapshot of the API coordinator, including per-item activity.
typedef CalendarSetupSnapshot = ({
  String mode,
  String objective,
  String cadence,
  int horizonDays,
  int batchCount,
  bool fitToCredits,
  List<String> platforms,
  Map<String, dynamic> priorities,
});

class CalendarState {
  CalendarState.fromSession(CalendarSession session)
    : setup = (
        mode: session.setup.mode,
        objective: session.setup.objective,
        cadence: session.setup.cadence,
        horizonDays: session.setup.horizonDays,
        batchCount: session.setup.batchCount,
        fitToCredits: session.setup.fitToCredits,
        platforms: List.unmodifiable(session.setup.platforms),
        priorities: Map.unmodifiable(session.setup.productModes),
      ),
      overview = session.overview,
      products = List.unmodifiable(session.products),
      quote = session.quote,
      error = session.error,
      actionError = session.actionError,
      productError = session.productError,
      quoteError = session.quoteError,
      notice = session.notice,
      loading = session.loading,
      productsLoading = session.productsLoading,
      setupOverride = session.setupOverride,
      busy = Set.unmodifiable(session.busy),
      picked = Set.unmodifiable(session.picked),
      stage = session.overview == null
          ? 'loading'
          : session.isSetup
          ? 'setup'
          : session.overview!.plan!.status == 'plan_ready'
          ? 'plan'
          : 'operating';
  final CalendarSetupSnapshot setup;
  final CalendarOverview? overview;
  final List<CalendarProduct> products;
  final CalendarQuote? quote;
  final String? error;
  final String? actionError;
  final String? productError;
  final String? quoteError;
  final String? notice;
  final bool loading;
  final bool productsLoading;
  final bool setupOverride;
  final Set<String> busy;
  final Set<String> picked;
  final String stage;
}
