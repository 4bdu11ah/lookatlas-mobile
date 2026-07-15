part of '../../../dashboard/presentation/screens/dashboard_screen.dart';

Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) {
  final state = ref.read(_houseModelControllerProvider);
  var gender = state.genderFilter;
  var body = state.bodyFilter;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return _SheetFrame(
            title: 'Filter models',
            actions: [
              _ModelActionButton.secondary(
                label: 'Clear',
                full: true,
                onTap: () {
                  ref
                      .read(_houseModelControllerProvider.notifier)
                      .applyFilters();
                  Navigator.pop(context);
                },
              ),
              _ModelActionButton(
                label: 'Show models',
                full: true,
                onTap: () {
                  ref
                      .read(_houseModelControllerProvider.notifier)
                      .applyFilters(gender: gender, body: body);
                  Navigator.pop(context);
                },
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChoiceGroup<_ModelGender?>(
                  title: 'Gender',
                  value: gender,
                  values: const [
                    null,
                    _ModelGender.female,
                    _ModelGender.male,
                    _ModelGender.nonBinary,
                  ],
                  labelFor: (value) => value?.label ?? 'All genders',
                  onChanged: (value) => setSheetState(() => gender = value),
                ),
                const SizedBox(height: 24),
                _ChoiceGroup<_ModelBody?>(
                  title: 'Body type',
                  value: body,
                  values: const [null, ..._ModelBody.values],
                  labelFor: (value) => value?.label ?? 'All body types',
                  onChanged: (value) => setSheetState(() => body = value),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
