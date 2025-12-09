import 'package:expense_uangku/pages/analytic_page.dart';
import 'package:expense_uangku/pages/home_page.dart';

import '../../routes/name_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:persistent_bottom_nav_bar_v2/persistent_bottom_nav_bar_v2.dart';

class PersistenBottomNavBarDemo extends StatelessWidget {
  const PersistenBottomNavBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PersistentTabView(
        tabs: [
          PersistentTabConfig(
            screen: HomePage(),
            item: ItemConfig(
              icon: Icon(Icons.list_alt_sharp),
            ),
          ),
          PersistentTabConfig(
            screen: SizedBox.shrink(), // kosongkan
            item: ItemConfig(
              icon: GestureDetector(
                onTap: () {
                  context.goNamed(NameRoutes.addExpanse);
                },
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: Colors.white),
                ),
              ),
            ),
          ),
          PersistentTabConfig(
            screen: AnalyticPage(),
            item: ItemConfig(
              icon: Icon(Icons.query_stats_outlined),
            ),
          ),
        ],
        navBarBuilder: (navBarConfig) => Style13BottomNavBar(
          navBarConfig: navBarConfig,
          navBarDecoration: NavBarDecoration(
            color: Colors.white24, // 20% opacity saja
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            boxShadow: [
              BoxShadow(color: Colors.transparent),
            ],
          ),
        ),
      ),
    );
  }
}
