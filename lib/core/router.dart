import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/trip/presentation/destination_search_screen.dart';
import '../features/trip/presentation/fare_estimate_screen.dart';
import '../features/trip/presentation/matching_screen.dart';
import '../features/trip/presentation/trip_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/search',
      builder: (context, state) => const DestinationSearchScreen(),
    ),
    GoRoute(
      path: '/fare_estimate',
      builder: (context, state) {
        final lat =
            double.tryParse(state.uri.queryParameters['lat'] ?? '0') ?? 0;
        final lng =
            double.tryParse(state.uri.queryParameters['lng'] ?? '0') ?? 0;
        final name = state.uri.queryParameters['name'] ?? '目的地';
        return FareEstimateScreen(
          destinationLat: lat,
          destinationLng: lng,
          destinationName: name,
        );
      },
    ),
    GoRoute(
      path: '/matching',
      builder: (context, state) => const MatchingScreen(),
    ),
    GoRoute(path: '/trip', builder: (context, state) => const TripScreen()),
  ],
);
