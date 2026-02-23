import 'package:get_it/get_it.dart';
import '../domain/services/image_service.dart';
import '../implementations/services/mock_image_service.dart';
import '../implementations/services/tercen_image_service.dart';
import '../presentation/providers/image_overview_provider.dart';
import '../presentation/providers/theme_provider.dart';
import '../utils/tercen_url_parser.dart';

final getIt = GetIt.instance;

/// Setup dependency injection
///
/// useMocks: true for mock implementation, false for real Tercen API
void setupServiceLocator({bool useMocks = true}) {
  // Register services
  if (useMocks) {
    getIt.registerSingleton<ImageService>(MockImageService());
  } else {
    final urlParser = getIt<TercenUrlParser>();
    getIt.registerSingleton<ImageService>(TercenImageService(urlParser));
  }

  // Register providers (factories for new instances)
  getIt.registerFactory<ImageOverviewProvider>(
    () => ImageOverviewProvider(getIt<ImageService>()),
  );

  getIt.registerLazySingleton<ThemeProvider>(() => ThemeProvider());
}
