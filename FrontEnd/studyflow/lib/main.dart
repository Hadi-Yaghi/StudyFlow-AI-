import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'core/localization/locale_controller.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/storage/token_storage.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/ad_service.dart';
import 'services/notification_service.dart';
import 'services/revenuecat_service.dart';
import 'services/feature_access_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ThemeController.instance.init();
  await LocaleController.instance.init();

  // Configure RevenueCat SDK once at app launch
  await RevenueCatService.instance.initialize();

  // Check persistent login and identify user in RevenueCat
  final token = await TokenStorage.getToken();
  final userData = await TokenStorage.getUserData();
  final userId = userData['userId'];
  final bool hasActiveSession = token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;

  if (hasActiveSession) {
    await RevenueCatService.instance.logIn(userId);
    FeatureAccessService.instance.refreshScheduleUsage();
    FeatureAccessService.instance.syncSubscriptionWithBackend();
  }

  // Synchronize AdMob suppression based on RevenueCat Pro entitlement
  AdService.instance.adsEnabled = !RevenueCatService.instance.isPro;
  await AdService.instance.initialize();
  await NotificationService.instance.init();

  runApp(MyApp(
    initialScreen: hasActiveSession ? const HomeScreen() : const LoginScreen(),
  ));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({
    super.key,
    this.initialScreen = const LoginScreen(),
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ 
        ThemeController.instance,
        LocaleController.instance,
        RevenueCatService.instance,
        FeatureAccessService.instance,
      ]),
      builder: (context, _) {
        final themeMode = ThemeController.instance.themeMode;
        final locale = LocaleController.instance.locale;

        return MaterialApp(
          title: 'StudyFlow',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          locale: locale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: initialScreen,
        );
      },
    );
  }
}
