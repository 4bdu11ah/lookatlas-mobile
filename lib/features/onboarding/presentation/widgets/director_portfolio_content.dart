part of 'director_portfolio_modal.dart';

class _DirectorPortfolioContent {
  const _DirectorPortfolioContent({
    required this.story,
    required this.quote,
    required this.styleCharacteristics,
    required this.bestFor,
    required this.signatureApproach,
    required this.similarBrands,
    required this.captions,
  });

  factory _DirectorPortfolioContent.from(Director director) =>
      _DirectorPortfolioContent(
        story: director.story.split('\n\n'),
        quote: director.philosophy,
        styleCharacteristics: director.styleCharacteristics,
        bestFor: director.bestFor,
        signatureApproach: director.signature,
        similarBrands: director.brands.replaceAll(', ', ' / '),
        captions: director.portfolioDescriptions,
      );

  final List<String> story;
  final String quote;
  final List<String> styleCharacteristics;
  final List<String> bestFor;
  final String signatureApproach;
  final String similarBrands;
  final List<String> captions;
}
