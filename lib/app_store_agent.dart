import 'dart:io';

class AppStoreAgent {
  Future<<StoreSubmission> generateSubmission({
    required String appName,
    required String description,
    required List<String> features,
    required String category,
    required List<File> screenshots,
    String? privacyPolicyUrl,
  }) async {
    return StoreSubmission(
      appName: appName,
      title: appName + ' - ' + category + ' Made Simple',
      subtitle: features.take(3).join(' * '),
      shortDescription: description.substring(0, description.length > 80 ? 80 : description.length),
      fullDescription: description + '\n\nFEATURES:\n' + features.map((f) => '* ' + f).join('\n'),
      keywords: [appName.toLowerCase(), category.toLowerCase(), 'mobile', 'app'],
      category: category,
      privacyPolicyUrl: privacyPolicyUrl ?? 'https://kitsunebyte.app/privacy',
      screenshots: screenshots,
      featureGraphic: screenshots.first,
      storeAssets: StoreAssets(appIcon: screenshots.first, phoneScreenshots: screenshots.take(5).toList(), tabletScreenshots: []),
      submissionGuide: _buildGuide(),
    );
  }

  String _buildGuide() {
    return 'CHECKLIST:\n'
        '1. Apple: Developer Program (99/yr), upload via Xcode, review 1-2 days\n'
        '2. Google: Play Console (25), upload AAB, review hours\n'
        '3. Both need: screenshots, privacy policy, support email';
  }

  Future<void> walkthroughSubmission(StoreSubmission s, {void Function(String)? onStep}) async {
    for (final step in ['Creating accounts', 'Building signed APK', 'Uploading metadata', 'Submitting for review']) {
      onStep?.call(step);
      await Future.delayed(const Duration(seconds: 1));
    }
  }
}

class StoreSubmission {
  final String appName;
  final String title;
  final String subtitle;
  final String shortDescription;
  final String fullDescription;
  final List<String> keywords;
  final String category;
  final String privacyPolicyUrl;
  final List<File> screenshots;
  final File featureGraphic;
  final StoreAssets storeAssets;
  final String submissionGuide;
  StoreSubmission({required this.appName, required this.title, required this.subtitle, required this.shortDescription, required this.fullDescription, required this.keywords, required this.category, required this.privacyPolicyUrl, required this.screenshots, required this.featureGraphic, required this.storeAssets, required this.submissionGuide});
}

class StoreAssets {
  final File appIcon;
  final List<File> phoneScreenshots;
  final List<File> tabletScreenshots;
  final File? promoVideo;
  StoreAssets({required this.appIcon, required this.phoneScreenshots, required this.tabletScreenshots, this.promoVideo});
}
