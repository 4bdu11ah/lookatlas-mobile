part of '../screens/house_model_page.dart';

Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) {
  final state = ref.read(houseModelControllerProvider);
  var gender = state.genderFilter;
  var body = state.bodyFilter;
  return showAppBottomSheet<void>(
    context,
    isScrollControlled: true,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          return AppSheetFrame(
            title: 'Filter models',
            actions: [
              AppOutlinedButton(
                label: 'Clear',
                onPressed: () {
                  ref
                      .read(houseModelControllerProvider.notifier)
                      .applyFilters();
                  Navigator.pop(context);
                },
              ),
              PrimaryButton(
                label: 'Show models',
                onPressed: () {
                  ref
                      .read(houseModelControllerProvider.notifier)
                      .applyFilters(gender: gender, body: body);
                  Navigator.pop(context);
                },
              ),
            ],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChoiceGroup<HouseModelGender?>(
                  title: 'Gender',
                  value: gender,
                  values: const [
                    null,
                    HouseModelGender.female,
                    HouseModelGender.male,
                    HouseModelGender.nonBinary,
                  ],
                  labelFor: (value) => value?.label ?? 'All genders',
                  onChanged: (value) => setSheetState(() => gender = value),
                ),
                const SizedBox(height: 24),
                _ChoiceGroup<HouseModelBody?>(
                  title: 'Body type',
                  value: body,
                  values: const [null, ...HouseModelBody.values],
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
