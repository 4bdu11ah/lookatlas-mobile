part of 'workshop_screen.dart';

class WorkshopGuideScreen extends StatelessWidget {
  const WorkshopGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Workshop Guide',
        showBackButton: true,
      ),
      body: _WorkshopGuideContent(
        onClose: () => context.go(AppRoutes.workshop),
      ),
    );
  }
}
