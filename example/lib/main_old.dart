import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qibla_ar_finder/qibla_ar_finder.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  configureDependencies();
  runApp(const QiblaARFinderExample());
}

class QiblaARFinderExample extends StatelessWidget {
  const QiblaARFinderExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qibla AR Finder Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatelessWidget {
  const ExampleHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qibla AR Finder Examples'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            title: 'AR View (Clean)',
            description: 'AR with hidden UI elements',
            icon: Icons.view_in_ar,
            color: Colors.blue,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => getIt<ARCubit>()),
                    BlocProvider(create: (_) => getIt<TiltCubit>()),
                  ],
                  child: const ARQiblaPage(
                    config: ARPageConfig(
                      showTopBar: false,
                      showInstructions: false,
                      showCompassIndicators: false,
                      primaryColor: Colors.green,
                      retry: 'Retry',
                      moveLeftText: 'Move Left',
                      moveRightText: 'Move Right',
                      message: 'Rotate your phone to a vertical position.\n\n'
                          'Hold it upright so the compass can accurately detect the Qibla direction.',
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildExampleCard(
            context,
            title: 'AR View (Full UI)',
            description: 'AR with all UI elements visible',
            icon: Icons.dashboard,
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MultiBlocProvider(
                  providers: [
                    BlocProvider(create: (_) => getIt<ARCubit>()),
                    BlocProvider(create: (_) => getIt<TiltCubit>()),
                  ],
                  child: const ARQiblaPage(
                    config: ARPageConfig(
                      showTopBar: true,
                      showInstructions: true,
                      showCompassIndicators: true,
                      primaryColor: Colors.green,
                      customTitle: 'Find Qibla',
                      retry: 'Retry',
                       moveLeftText: 'Move Left',
                      moveRightText: 'Move Right',
                      message: 'Rotate your phone to a vertical position.\n\n'
                          'Hold it upright so the compass can accurately detect the Qibla direction.',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
