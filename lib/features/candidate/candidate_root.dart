import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pro_recruit_ai/features/candidate/screens/candidate_profile_hub.dart';
import 'package:pro_recruit_ai/features/candidate/screens/elite_certificates_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/job_alert_preferences_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/messages_list_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/profile_views_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/resume_vault_screen.dart';
import 'package:pro_recruit_ai/features/candidate/screens/saved_jobs_screen.dart';
import 'package:pro_recruit_ai/features/candidate/tabs/ai_prep_tab.dart';
import 'package:pro_recruit_ai/features/candidate/tabs/growth_tab.dart';
import 'package:pro_recruit_ai/features/candidate/tabs/network_tab.dart';
import 'package:pro_recruit_ai/features/candidate/tabs/scout_tab.dart';
import 'package:pro_recruit_ai/features/candidate/tabs/trust_id_tab.dart';
import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';

class CandidateRoot extends StatefulWidget {
  const CandidateRoot({super.key});

  @override
  State<CandidateRoot> createState() => _CandidateRootState();
}

class _CandidateRootState extends State<CandidateRoot> {
  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _idx = 0;

  final List<Widget> _tabs = const [
    ScoutTab(),
    AIPrepTab(),
    TrustIDTab(),
    NetworkTab(),
    GrowthTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _professionalDrawer(),
      body: Stack(
        children: [
          AnimatedBackgroundWrapper(
            child: IndexedStack(
              index: _idx,
              children: _tabs,
            ),
          ),
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.menu, color: AppColors.primary),
              onPressed: () => _scaffoldKey.currentState!.openDrawer(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        type: BottomNavigationBarType.fixed,
        onTap: (i) => setState(() => _idx = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Scout"),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_alt), label: "AI Prep"),
          BottomNavigationBarItem(icon: Icon(Icons.verified_user), label: "Trust ID"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Network"),
          BottomNavigationBarItem(icon: Icon(Icons.auto_graph), label: "Growth"),
        ],
      ),
    );
  }

  Widget _professionalDrawer() => Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E40AF)]),
              ),
              accountName: const Text(
                "Candidate",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              accountEmail: const Row(
                children: [
                  Text("Elite Identity Verified", style: TextStyle(color: Colors.white70, fontSize: 10)),
                  SizedBox(width: 4),
                  Icon(Icons.verified, color: Colors.white, size: 12),
                ],
              ),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF1E40AF)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_pin, color: Color(0xFF2563EB), size: 22),
              title: const Text(
                "Update Profile",
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const CandidateProfileHub()),
                );
              },
            ),
            _drawerNavTile(
              Icons.folder_special_outlined,
              "Career Portfolio",
              const Color(0xFF16A34A),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const EliteCertificatesScreen()),
                );
              },
            ),
            _drawerNavTile(
              Icons.inventory_2_outlined,
              "Resume Vault",
              const Color(0xFF0F766E),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const ResumeVaultScreen()),
                );
              },
            ),
            _drawerNavTile(
              Icons.bookmark_border,
              "Saved Jobs",
              const Color(0xFFB45309),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SavedJobsScreen()),
                );
              },
            ),
            _drawerNavTile(
              Icons.chat_bubble_outline,
              "Messages",
              const Color(0xFF7C3AED),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const MessagesListScreen()),
                );
              },
            ),
            _drawerNavTile(
              Icons.notifications_active_outlined,
              "Job Alerts",
              const Color(0xFFDC2626),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const JobAlertPreferencesScreen()),
                );
              },
            ),
            _drawerNavTile(
              Icons.visibility_outlined,
              "Profile Views",
              const Color(0xFF0891B2),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const ProfileViewsScreen()),
                );
              },
            ),
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

  Widget _drawerNavTile(IconData i, String t, Color c, {VoidCallback? onTap}) => ListTile(
        leading: Icon(i, color: c, size: 22),
        title: Text(t, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700, fontSize: 13)),
        onTap: onTap,
      );
}
