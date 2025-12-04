/// Qibla AR Finder
///
/// A professional Flutter package for finding Qibla direction using AR, compass, and panorama views.
///
/// Features:
/// - AR View with camera overlay (Android & iOS)
/// - Traditional compass with Qibla indicator
/// - 360° panorama view
/// - Automatic GPS location detection
/// - Device orientation tracking
/// - Vertical position warning
/// - Cross-platform support
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
/// MultiBlocProvider(
///   providers: [
///     BlocProvider(create: (_) => getIt<QiblaCubit>()),
///     BlocProvider(create: (_) => getIt<ARCubit>()),
///     BlocProvider(create: (_) => getIt<TiltCubit>()),
///   ],
///   child: ARQiblaPage(),
/// )
/// ```
library;

// Core - Dependency Injection
export 'core/di/injection.dart';

// Domain - Entities
export 'domain/entities/qibla_data.dart';
export 'domain/entities/heading_data.dart';
export 'domain/entities/location_data.dart';
export 'domain/entities/ar_node_data.dart';

// Domain - Use Cases
export 'domain/usecases/calculate_qibla_direction.dart';
export 'domain/usecases/get_user_location.dart';
export 'domain/usecases/get_device_heading.dart';
export 'domain/usecases/get_device_tilt.dart';
export 'domain/usecases/get_ar_qibla_bearing.dart';
export 'domain/usecases/check_location_services.dart';

// Presentation - Pages
export 'presentation/pages/ar_qibla_page.dart';
export 'presentation/pages/qibla_compass_page.dart';
export 'presentation/pages/panorama_kaaba_page.dart';

// Presentation - Widgets
export 'presentation/widgets/ar_view_enhanced_android.dart';
export 'presentation/widgets/ar_view_enhanced_ios.dart';
export 'presentation/widgets/panorama_viewer.dart';
export 'presentation/widgets/vertical_position_warning.dart';

// Presentation - State Management (Cubits)
export 'presentation/cubits/qibla_cubit.dart';
export 'presentation/cubits/qibla_state.dart';
export 'presentation/cubits/ar_cubit.dart';
export 'presentation/cubits/ar_state.dart';
export 'presentation/cubits/tilt_cubit.dart';
export 'presentation/cubits/tilt_state.dart';
