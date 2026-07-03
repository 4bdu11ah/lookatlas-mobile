import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:look_atlas/features/ai/data/claude_ai_repository.dart';
import 'package:look_atlas/features/ai/domain/ai_repository.dart';

/// Dependency injection for the AI feature. Presentation code (controllers,
/// screens) depends on these providers, never on the concrete implementations
/// directly.

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => ClaudeAiRepository(),
);
