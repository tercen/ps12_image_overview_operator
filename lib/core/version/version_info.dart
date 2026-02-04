/// Version and repository information for the app
class VersionInfo {
  /// GitHub repository URL
  static const String gitRepo = 'https://github.com/tercen/ps12_image_overview_operator';

  /// Git version (tag or short commit hash)
  /// Empty during development, populated at build time
  static const String gitVersion = '';

  /// Returns the URL to the specific commit or tag on GitHub
  static String get versionUrl {
    if (gitVersion.isEmpty) {
      return gitRepo;
    }

    // If version looks like a tag (e.g., v1.0.0), link to releases/tag
    // Otherwise assume it's a commit hash and link to commit
    if (gitVersion.startsWith('v') || gitVersion.contains('.')) {
      return '$gitRepo/releases/tag/$gitVersion';
    }
    return '$gitRepo/commit/$gitVersion';
  }
}
