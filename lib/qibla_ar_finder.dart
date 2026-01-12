/// Qibla AR Finder
///
/// A professional Flutter package for finding Qibla direction using AR.
///
/// Features:
/// - AR View with world-anchored Kaaba (Android & iOS)
/// - Automatic GPS location detection
/// - Real-time compass heading tracking
/// - Cross-platform support (ARCore for Android, ARKit for iOS)
///
/// Example usage:
/// ```dart
/// import 'package:qibla_ar_finder/qibla_ar_finder.dart';
/// import 'package:flutter_bloc/flutter_bloc.dart';
///
/// // Initialize dependency injection
/// configureDependencies();
///
/// // Use AR Qibla Page
/// BlocProvider(
///   create: (_) => getIt<ARCubit>(),
///   child: ARQiblaPage(),
/// )
/// ```
library;

// Core - Dependency Injection
export 'core/di/injection.dart';

// Domain - Entities
export 'domain/entities/location_data.dart';
export 'domain/entities/ar_node_data.dart';

// Domain - Use Cases
export 'domain/usecases/get_user_location.dart';
export 'domain/usecases/get_device_heading.dart';
export 'domain/usecases/get_device_tilt.dart';
export 'domain/usecases/get_ar_qibla_bearing.dart';

// Presentation - Pages
export 'presentation/pages/ar_qibla_page.dart';

// Presentation - Widgets
export 'presentation/widgets/ar_view_enhanced_android.dart';
export 'presentation/widgets/ar_view_enhanced_ios.dart';

// Presentation - Widgets
export 'presentation/widgets/vertical_position_warning.dart';

// Presentation - State Management (Cubits)
export 'presentation/cubits/ar_cubit.dart';
export 'presentation/cubits/ar_state.dart';
export 'presentation/cubits/tilt_cubit.dart';
export 'presentation/cubits/tilt_state.dart';

// Services
export 'services/qiblah_service.dart';
export 'services/ar_initialization_manager.dart';
export 'services/qibla_initialization_manager.dart';

// Utils
export 'utils/qiblah_utils.dart';
