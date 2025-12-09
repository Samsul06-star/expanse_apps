import 'package:flutter/material.dart';
import 'package:expense_uangku/core/helpers/navbar.dart';
import 'package:expense_uangku/pages/add_expanse_page.dart';
import 'package:expense_uangku/pages/detail_expanse_page.dart';
import 'package:expense_uangku/pages/login_page.dart';
import 'package:expense_uangku/pages/register_page.dart';
import 'package:expense_uangku/pages/setting_profile_page.dart';
import 'package:expense_uangku/pages/view_all_expanse_page.dart';
import 'package:go_router/go_router.dart';

import 'name_routes.dart';
import 'package:expense_uangku/services/users_api.dart'; // for getToken()

class AuthNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  AuthNotifier() {
    _initialize();
  }

  Future<void> _initialize() async {
    final token = await UsersApi.getToken();
    print('AuthNotifier init token: $token');
    _isLoggedIn = token != null && token.isNotEmpty;
    notifyListeners();
  }

  void setLoggedIn(bool v) {
    _isLoggedIn = v;
    notifyListeners();
  }
}

class AppRoutes {
  final AuthNotifier auth = AuthNotifier();

  late final GoRouter router;

  AppRoutes() {
    router = GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (BuildContext context, GoRouterState state) {
        // Use state.uri.path to get current path in a cross-version-safe way
        final current = state.uri.path;
        final isOnAuthPage = current == '/login' || current == '/register';

        if (auth.isLoggedIn) {
          if (isOnAuthPage) return '/';
          return null;
        } else {
          if (!isOnAuthPage) return '/login';
          return null;
        }
      },
      routes: [
        GoRoute(
          path: '/',
          name: NameRoutes.home,
          builder: (context, state) => const PersistenBottomNavBarDemo(),
          routes: [
            GoRoute(
              path: 'add-expanse',
              name: NameRoutes.addExpanse,
              builder: (context, state) => const AddExpansePage(),
            ),
            GoRoute(
              path: 'detail-expanse/:id',
              name: NameRoutes.detailExpanse,
              builder: (context, state) {
                final id = int.parse(state.pathParameters['id'] ?? '0');
                return DetailExpansePage(expanseId: id);
              },
            ),
            GoRoute(
              path: 'view-expanse',
              name: NameRoutes.viewAllExpanse,
              builder: (context, state) => const ViewAllExpansePage(),
            ),
            GoRoute(
              path: 'settings-profile',
              name: NameRoutes.settingProfile,
              builder: (context, state) => const SettingProfilePage(),
            ),
          ],
        ),
        GoRoute(
          path: '/login',
          name: NameRoutes.login,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          name: NameRoutes.register,
          builder: (context, state) => const RegisterPage(),
        ),
      ],
    );
  }
}

// Global appRoutes instance to be used by main and pages for auth updates
final appRoutes = AppRoutes();
