import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:qibla_ar_finder/qibla_ar_finder.dart';
import 'fixed_qibla_screen.dart';
import 'optimized_qibla_screen.dart';
import 'loading_comparison_screen.dart';
import 'preinitialized_qibla_screen.dart';

/// Example demonstrating AR pre-initialization in a consuming project
/// 
/// This example shows how to initialize AR during app startup,
/// eliminating the loading indicator when the AR screen opens.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Reduce log noise in debug mode (optional)
  if (kDebugMode) {
    // You can filter out specific log messages if needed
    // This is optional and doesn't affect functionality
  }

  // Step 1: Configure package dependencies
  configureDependencies();

  // Step 2: Pre-initialize AR (non-blocking)
  // This starts AR initialization in the background
  ARInitializationManager.instance.initialize(
    timeout: const Duration(seconds: 45),
    skipLocationIfFailed: true, // Continue even if GPS fails
  ).then((success) {
    debugPrint('AR pre-initialization: ${success ? "✅ success" : "❌ failed"}');
  });

  // Step 3: Pre-initialize Qibla (non-blocking)
  // This starts Qibla initialization in the background
  QiblaInitializationManager.instance.initialize(
    timeout: const Duration(seconds: 45),
    skipLocationIfFailed: true, // Continue even if GPS fails
  ).then((success) {
    debugPrint('Qibla pre-initialization: ${success ? "✅ success" : "❌ failed"}');
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qibla AR Finder Demo',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla Finder'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // AR Initialization Status Card
            const ARStatusCard(),
            
            const SizedBox(height: 40),
            
            // Smart AR Button (adapts based on initialization state)
            const SmartARButton(),
            
            const SizedBox(height: 20),
            
            // Pre-initialized Qibla Screen (NEW!)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PreinitializedQiblaScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.flash_on),
              label: const Text('Qibla (Pre-initialized)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // // Loading Comparison Screen
            // ElevatedButton.icon(
            //   onPressed: () {
            //     Navigator.of(context).push(
            //       MaterialPageRoute(
            //         builder: (_) => const LoadingComparisonScreen(),
            //       ),
            //     );
            //   },
            //   icon: const Icon(Icons.compare_arrows),
            //   label: const Text('Compare Loading Speed'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.purple,
            //     foregroundColor: Colors.white,
            //     padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            //     textStyle: const TextStyle(fontSize: 18),
            //   ),
            // ),
            
            // const SizedBox(height: 40),
            
            // // Individual buttons
            // Row(
            //   children: [
            //     Expanded(
            //       child: ElevatedButton.icon(
            //         onPressed: () {
            //           Navigator.of(context).push(
            //             MaterialPageRoute(
            //               builder: (_) => const FixedQiblaScreen(),
            //             ),
            //           );
            //         },
            //         icon: const Icon(Icons.explore),
            //         label: const Text('Fixed'),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.blue,
            //           foregroundColor: Colors.white,
            //           padding: const EdgeInsets.symmetric(vertical: 12),
            //         ),
            //       ),
            //     ),
            //     const SizedBox(width: 10),
            //     Expanded(
            //       child: ElevatedButton.icon(
            //         onPressed: () {
            //           Navigator.of(context).push(
            //             MaterialPageRoute(
            //               builder: (_) => const OptimizedQiblaScreen(),
            //             ),
            //           );
            //         },
            //         icon: const Icon(Icons.speed),
            //         label: const Text('Fast'),
            //         style: ElevatedButton.styleFrom(
            //           backgroundColor: Colors.orange,
            //           foregroundColor: Colors.white,
            //           padding: const EdgeInsets.symmetric(vertical: 12),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            
            // const SizedBox(height: 20),
            
            // Manual Retry Button
            // ElevatedButton.icon(
            //   onPressed: () {
            //     ARInitializationManager.instance.reset();
            //     ARInitializationManager.instance.initialize();
            //   },
            //   icon: const Icon(Icons.refresh),
            //   label: const Text('Retry Initialization'),
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.orange,
            //     foregroundColor: Colors.white,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

/// Widget that displays current AR initialization status
class ARStatusCard extends StatelessWidget {
  const ARStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ARInitializationState>(
      stream: ARInitializationManager.instance.stateStream,
      initialData: ARInitializationManager.instance.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        return Card(
          margin: const EdgeInsets.all(20),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIcon(state),
                const SizedBox(height: 12),
                Text(
                  _getStatusText(state),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _getStatusDescription(state),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                if (state.isInitialized) ...[
                  const SizedBox(height: 16),
                  _buildInitializedInfo(state),
                ],
                if (state.hasFailed) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.errorMessage ?? 'Unknown error',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(ARInitializationState state) {
    if (state.isInitializing) {
      return const SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(strokeWidth: 3),
      );
    } else if (state.isInitialized) {
      return const Icon(
        Icons.check_circle,
        color: Colors.green,
        size: 48,
      );
    } else if (state.hasFailed) {
      return const Icon(
        Icons.error,
        color: Colors.red,
        size: 48,
      );
    } else {
      return const Icon(
        Icons.hourglass_empty,
        color: Colors.grey,
        size: 48,
      );
    }
  }

  String _getStatusText(ARInitializationState state) {
    switch (state.status) {
      case ARInitializationStatus.notInitialized:
        return 'AR Not Initialized';
      case ARInitializationStatus.initializing:
        return 'Initializing AR...';
      case ARInitializationStatus.initialized:
        return 'AR Ready!';
      case ARInitializationStatus.failed:
        return 'Initialization Failed';
    }
  }

  String _getStatusDescription(ARInitializationState state) {
    switch (state.status) {
      case ARInitializationStatus.notInitialized:
        return 'AR will initialize when you open the AR view';
      case ARInitializationStatus.initializing:
        return 'Acquiring GPS location and calculating Qibla direction...';
      case ARInitializationStatus.initialized:
        return 'AR is ready to use. No loading when you open AR view!';
      case ARInitializationStatus.failed:
        return 'AR will retry when you open the AR view';
    }
  }

  Widget _buildInitializedInfo(ARInitializationState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          if (state.qiblaBearing != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.explore, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Qibla: ${state.qiblaBearing!.toStringAsFixed(1)}°',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          if (state.userLocation != null) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 20, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Location: ${state.userLocation!.latitude.toStringAsFixed(4)}, '
                  '${state.userLocation!.longitude.toStringAsFixed(4)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
          if (state.initializedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              'Initialized: ${_formatTime(state.initializedAt!)}',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}s ago';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else {
      return '${diff.inHours}h ago';
    }
  }
}

/// Smart button that adapts based on AR initialization state
class SmartARButton extends StatelessWidget {
  const SmartARButton({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ARInitializationState>(
      stream: ARInitializationManager.instance.stateStream,
      initialData: ARInitializationManager.instance.state,
      builder: (context, snapshot) {
        final state = snapshot.data!;
        
        return ElevatedButton.icon(
          onPressed: state.isInitializing
              ? null // Disable while initializing
              : () => _handleButtonPress(context, state),
          icon: Icon(_getButtonIcon(state)),
          label: Text(_getButtonText(state)),
          style: ElevatedButton.styleFrom(
            backgroundColor: state.isInitialized ? Colors.green : Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: const TextStyle(fontSize: 18),
          ),
        );
      },
    );
  }

  IconData _getButtonIcon(ARInitializationState state) {
    if (state.isInitialized) {
      return Icons.view_in_ar;
    } else if (state.isInitializing) {
      return Icons.hourglass_empty;
    } else {
      return Icons.play_arrow;
    }
  }

  String _getButtonText(ARInitializationState state) {
    if (state.isInitialized) {
      return 'Open AR View (Instant!)';
    } else if (state.isInitializing) {
      return 'Initializing...';
    } else {
      return 'Initialize & Open AR';
    }
  }

  Future<void> _handleButtonPress(
    BuildContext context,
    ARInitializationState state,
  ) async {
    if (state.isInitialized) {
      // AR is ready, navigate immediately
      _navigateToAR(context);
    } else {
      // Initialize first, then navigate
      _showInitializationDialog(context);
      
      final success = await ARInitializationManager.instance.initialize(
        timeout: const Duration(seconds: 45),
        skipLocationIfFailed: true,
      );
      
      if (context.mounted) {
        Navigator.of(context).pop(); // Close dialog
        
        if (success || ARInitializationManager.instance.state.isInitialized) {
          _navigateToAR(context);
        } else {
          _showErrorDialog(context);
        }
      }
    }
  }

  void _showInitializationDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => StreamBuilder<ARInitializationState>(
        stream: ARInitializationManager.instance.stateStream,
        builder: (context, snapshot) {
          final state = snapshot.data;
          return AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text(
                  state?.isInitializing ?? false
                      ? 'Acquiring GPS location...\nThis may take 30-60 seconds'
                      : 'Initializing AR...',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Initialization Failed'),
        content: const Text(
          'AR initialization failed, but you can still try opening the AR view. '
          'It will attempt to initialize again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToAR(context);
            },
            child: const Text('Try Anyway'),
          ),
        ],
      ),
    );
  }

  void _navigateToAR(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => getIt<ARCubit>()),
            BlocProvider(create: (_) => getIt<TiltCubit>()),
          ],
          child: ARQiblaPage(
            config: ARPageConfig(
              primaryColor: Colors.green,
              showTopBar: true,
              showInstructions: true,
              showCompassIndicators: true,
              customTitle: 'AR Qibla Direction',
              moveRightText: 'Turn Right →',
              moveLeftText: '← Turn Left',
              message: 'Hold your phone vertically for best results',
              retry: 'Retry',
              cardMSGColor: Colors.orange,
            ),
          ),
        ),
      ),
    );
  }
}
