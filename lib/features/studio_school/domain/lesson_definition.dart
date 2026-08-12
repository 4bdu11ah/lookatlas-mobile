import 'package:flutter/material.dart';
import 'package:look_atlas/features/studio_school/domain/welcome_lesson.dart';

@immutable
class LessonCardDefinition {
  const LessonCardDefinition({
    required this.title,
    required this.body,
    this.hasCalculator = false,
  });

  final String title;
  final String body;
  final bool hasCalculator;
}

@immutable
class SchoolLink {
  const SchoolLink({required this.label, required this.location});

  final String label;
  final String location;
}

@immutable
class LessonDefinition {
  const LessonDefinition({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.cards,
    this.tryLink,
  });

  final WelcomeLessonId id;
  final String title;
  final String tagline;
  final IconData icon;
  final List<LessonCardDefinition> cards;
  final SchoolLink? tryLink;
}

@immutable
class DeepGuideDefinition {
  const DeepGuideDefinition({
    required this.title,
    required this.description,
    required this.icon,
    required this.tabId,
  });

  final String title;
  final String description;
  final IconData icon;
  final String tabId;
}
