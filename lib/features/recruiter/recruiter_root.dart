import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';
import 'package:pro_recruit_ai/shared/notifications_screen.dart';

// Extracted Tabs
import 'package:pro_recruit_ai/features/recruiter/tabs/recruiter_console_tab.dart';
import 'package:pro_recruit_ai/features/recruiter/tabs/hiring_swipe_tab.dart';
import 'package:pro_recruit_ai/features/recruiter/tabs/pipeline_dashboard_tab.dart';
import 'package:pro_recruit_ai/features/recruiter/tabs/offers_hub_tab.dart';
import 'package:pro_recruit_ai/features/recruiter/tabs/enterprise_org_tab.dart';

// Drawer Target Screens
import 'package:pro_recruit_ai/features/recruiter/screens/team_management_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/kpi_analytics_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/subscription_plan_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/usage_credits_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/messages_list_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/screens/saved_candidates_screen.dart';

// Entry Point for the Recruiter World
class RecruiterRoot extends StatelessWidget {
  const RecruiterRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecruiterMasterHub();
  }
}

class RecruiterMasterHub extends StatefulWidget {
  const RecruiterMasterHub({super.key});

  @override
  State<RecruiterMasterHub> createState() => _RecruiterMasterHubState();
}

class _RecruiterMasterHubState extends State<RecruiterMasterHub> {
  int _idx = 0;
  final GlobalKey<ScaffoldState> _scafKey = GlobalKey<ScaffoldState>();

  void _navigateToTab(int index) {
    setState(() => _idx = index);
  }

  Widget _buildMasterDrawer() => Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E40AF)]),
              ),
              accountName: const Text(
                "Recruiter",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              accountEmail: const Text(
                "Enterprise Global Access ✓",
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: CustomPaint(
                  size: const Size(40, 40),
                  painter: AshWheelPainter(wheelColor: const Color(0xFF1E40AF)),
                ),
              ),
            ),
            _drawerItem("Team Management", Icons.groups, const Color(0xFF2563EB), onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const TeamManagementScreen()),
              );
            }),
            _drawerItem("Analytics", Icons.query_stats, Colors.purple, onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (c) => const KPIAnalyticsScreen()));
            }),
            _drawerItem("Subscription Plan", Icons.workspace_premium_rounded, const Color(0xFFEA580C), onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const SubscriptionPlanScreen()),
              );
            }),
            _drawerItem("Usage Credits", Icons.account_balance_wallet_rounded, const Color(0xFF16A34A), onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const UsageCreditsScreen()),
              );
            }),
            _drawerItem("Messages", Icons.chat_bubble_outline, const Color(0xFF7C3AED), onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (c) => const RecruiterMessagesListScreen()));
            }),
            _drawerItem("Saved Candidates", Icons.bookmark_outline, const Color(0xFFDB2777), onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => const RecruiterSavedCandidatesScreen()),
              );
            }),
            const Divider(),
            AnimatedBuilder(
              animation: ThemeController.instance,
              builder: (context, _) => SwitchListTile(
                secondary: Icon(
                  ThemeController.instance.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: const Color(0xFF1E40AF),
                ),
                title: const Text(
                  "Dark Mode",
                  style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                value: ThemeController.instance.isDarkMode,
                onChanged: (v) => ThemeController.instance.setDarkMode(v),
              ),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFDC2626)),
              title: const Text("Logout", style: TextStyle(color: Colors.black87, fontSize: 13)),
              onTap: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
              },
            ),
            SizedBox(height: AppSpacing.lg),
          ],
        ),
      );

  Widget _drawerItem(String t, IconData i, Color c, {VoidCallback? onTap}) => ListTile(
        leading: Icon(i, color: c),
        title: Text(t, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.black45),
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scafKey,
      drawer: _buildMasterDrawer(),
      appBar: AppBar(
        actions: const [NotificationBell()],
        leading: IconButton(
          icon: Icon(Icons.menu_open_rounded, color: AppColors.primary),
          onPressed: () => _scafKey.currentState!.openDrawer(),
        ),
        title: Text("Career Root Console", style: GoogleFonts.lobster(color: AppColors.primary)),
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        elevation: 0,
        centerTitle: true,
      ),
      body: AnimatedBackgroundWrapper(
        child: IndexedStack(
          index: _idx,
          children: [
            RecruiterConsoleTab(onNavigateToTab: _navigateToTab),
            const HiringSwipeTab(),
            const PipelineDashboardTab(),
            const OffersHubTab(),
            const EnterpriseOrgTab(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Console"),
          BottomNavigationBarItem(icon: Icon(Icons.swipe_rounded), label: "Hiring"),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree_outlined), label: "Pipeline"),
          BottomNavigationBarItem(icon: Icon(Icons.card_membership), label: "Offers"),
          BottomNavigationBarItem(icon: Icon(Icons.business_center), label: "Org"),
        ],
      ),
    );
  }
}
