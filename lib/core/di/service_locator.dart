import 'package:get_it/get_it.dart';

import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/datasources/mock_auth_data_source.dart';
import '../../features/auth/data/datasources/firebase_auth_data_source.dart';

import '../../features/games/data/repositories/game_repository_impl.dart';
import '../../features/games/domain/repositories/game_repository.dart';
import '../../features/games/data/datasources/game_remote_data_source.dart';
import '../../features/games/data/datasources/mock_game_data_source.dart';
import '../../features/games/data/datasources/firestore_game_data_source.dart';

import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/data/datasources/task_remote_data_source.dart';
import '../../features/tasks/data/datasources/mock_task_data_source.dart';
import '../../features/tasks/data/datasources/firebase_task_data_source.dart';

import '../../features/telephone/data/repositories/telephone_repository_impl.dart';
import '../../features/telephone/domain/repositories/telephone_repository.dart';
import '../../features/telephone/data/datasources/telephone_remote_data_source.dart';
import '../../features/telephone/data/datasources/mock_telephone_data_source.dart';
import '../../features/telephone/data/datasources/firestore_telephone_data_source.dart';

import '../services/ad_service_simple.dart';
import '../services/purchase_service_simple.dart';
import '../services/ai_task_service.dart';
import '../services/notification_service.dart';
import '../services/ar/ar_capability_service.dart';

final GetIt sl = GetIt.instance;

class ServiceLocator {
  static Future<void> init({bool useMockServices = true}) async {
    // Data Sources
    if (useMockServices) {
      sl.registerLazySingleton<AuthRemoteDataSource>(
        () => MockAuthDataSource(),
      );
      sl.registerLazySingleton<GameRemoteDataSource>(
        () => MockGameDataSource(),
      );
      sl.registerLazySingleton<TaskRemoteDataSource>(
        () => MockTaskDataSource(),
      );
      sl.registerLazySingleton<TelephoneRemoteDataSource>(
        () => MockTelephoneDataSource(),
      );
    } else {
      // Firebase implementations
      sl.registerLazySingleton<AuthRemoteDataSource>(
        () => FirebaseAuthDataSource(),
      );
      sl.registerLazySingleton<GameRemoteDataSource>(
        () => FirestoreGameDataSource(),
      );
      sl.registerLazySingleton<TaskRemoteDataSource>(
        () => FirebaseTaskDataSource(),
      );
      sl.registerLazySingleton<TelephoneRemoteDataSource>(
        () => FirestoreTelephoneDataSource(),
      );
    }

    // Repositories
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(sl()),
    );
    sl.registerLazySingleton<GameRepository>(
      () => GameRepositoryImpl(sl()),
    );
    sl.registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(sl()),
    );
    sl.registerLazySingleton<TelephoneRepository>(
      () => TelephoneRepositoryImpl(sl()),
    );

    // AR capability gating. Single real implementation on all builds — it
    // self-gates by platform/permission and never throws, so there is no need
    // for a separate mock. Tests construct ArCapabilityServiceImpl directly
    // with injected platform seams.
    sl.registerLazySingleton<ArCapabilityService>(
      () => ArCapabilityServiceImpl(),
    );


    // Additional Services
    if (useMockServices) {
      sl.registerLazySingleton<AdService>(() => MockAdService());
      sl.registerLazySingleton<PurchaseService>(() => MockPurchaseService());
      sl.registerLazySingleton<AITaskService>(() => MockAITaskService());
      sl.registerLazySingleton<NotificationService>(
          () => MockNotificationService());
    } else {
      sl.registerLazySingleton<AdService>(() => AdServiceImpl());
      sl.registerLazySingleton<PurchaseService>(() => PurchaseServiceImpl());
      sl.registerLazySingleton<AITaskService>(() => AITaskServiceImpl());
      sl.registerLazySingleton<NotificationService>(
          () => FcmNotificationService());
    }
  }
}

