class AppImages {
  AppImages._();

  // -- IMPORTS CLASS -- //
  static const appLogos = AppLogos();
  static const appIcons = AppIcons();
  static const coreImages = CoreImages();
}

class AppLogos {
  const AppLogos();
  final String appLogo = 'assets/logos/app-logo.png';
}

class AppIcons {
  const AppIcons();
  final String gmailLogo = 'assets/icons/gmail-logo.png';
}

class CoreImages {
  const CoreImages();
  final String deviceNotSupported = 'assets/images/device-not-supported.jpg';
}
