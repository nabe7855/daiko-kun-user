import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/trip/presentation/destination_search_screen.dart';
import '../features/trip/presentation/fare_estimate_screen.dart';
import '../features/trip/presentation/matching_screen.dart';
import '../features/trip/presentation/rating_screen.dart';
import '../features/trip/presentation/trip_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phone = state.uri.queryParameters['phone'] ?? '';
        return OtpScreen(phoneNumber: phone);
      },
    ),
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

        double? startLat;
        if (state.uri.queryParameters['startLat'] != null) {
          startLat = double.tryParse(state.uri.queryParameters['startLat']!);
        }

        double? startLng;
        if (state.uri.queryParameters['startLng'] != null) {
          startLng = double.tryParse(state.uri.queryParameters['startLng']!);
        }

        return FareEstimateScreen(
          destinationLat: lat,
          destinationLng: lng,
          destinationName: name,
          startLat: startLat,
          startLng: startLng,
        );
      },
    ),
    GoRoute(
      path: '/matching',
      builder: (context, state) {
        final requestId = state.uri.queryParameters['requestId'];
        return MatchingScreen(requestId: requestId);
      },
    ),
    GoRoute(
      path: '/trip',
      builder: (context, state) {
        final requestId = state.uri.queryParameters['requestId'];
        return TripScreen(requestId: requestId);
      },
    ),
    GoRoute(
      path: '/rating',
      builder: (context, state) {
        final requestId = state.uri.queryParameters['requestId'] ?? '';
        final fareStr = state.uri.queryParameters['fare'] ?? '0';
        final fare = double.tryParse(fareStr) ?? 0.0;
        return RatingScreen(requestId: requestId, fare: fare);
      },
    ),
  ],
);
