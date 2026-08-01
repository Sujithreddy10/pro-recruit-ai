import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// PERMANENT FIX: Universal Scroll Behavior for Mac M4 Trackpads/Mouse
class GlobalScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}

// --- DATA MODEL: ADVANCED NAUKRI-STYLE FILTERING ---
class JobPost {
  final String title, company, location, mode, salary, match, sector;
  JobPost({
    required this.title, required this.company, required this.location, 
    required this.mode, required this.salary, required this.match, required this.sector
  });
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool otpSent = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Create Account")),
    body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(children: [
      UIHelper.inputField("Full Name", icon: Icons.person_outline),
      UIHelper.inputField("Email / Phone", icon: Icons.contact_mail_outlined),
      UIHelper.inputField("Password", icon: Icons.lock_outline, obscure: true),
      const SizedBox(height: 20),
      if (!otpSent)
        ElevatedButton(onPressed: () => setState(() => otpSent = true), child: const Text("Send Verification OTP"))
      else ...[
        UIHelper.inputField("Enter OTP", icon: Icons.security),
        const SizedBox(height: 30),
        ElevatedButton(style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 55)),
          onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const MainNavigationHolder())), 
          child: const Text("Verify & Register")),
      ]
    ])),
  );
}

// --- 3. MAIN NAVIGATION HUB (STABLE VIEW CONTROL) ---
class MainNavigationHolder extends StatefulWidget {
  const MainNavigationHolder({super.key});
  @override
  State<MainNavigationHolder> createState() => _MainNavigationHolderState();
}

class _MainNavigationHolderState extends State<MainNavigationHolder> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _onTabTapped(int index) {
    _pageController.jumpToPage(index);
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageView(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(), // Controls swipe stability
      children: const [
        JobFeedScreen(), TrackerScreen(), TrustBreakdownScreen(), NotificationScreen(), UserProfileScreen()
      ],
    ),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _currentIndex, onTap: _onTabTapped,
      selectedItemColor: const Color(0xFF2DD4BF), unselectedItemColor: Colors.white24,
      type: BottomNavigationBarType.fixed, backgroundColor: const Color(0xFF020617),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.bolt), label: "Feed"),
        BottomNavigationBarItem(icon: Icon(Icons.radar), label: "Tracker"),
        BottomNavigationBarItem(icon: Icon(Icons.shield_outlined), label: "Trust"),
        BottomNavigationBarItem(icon: Icon(Icons.notifications_none), label: "Alerts"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Account"),
      ]));
}

// --- TAB 1: ADVANCED SMART SEARCH ENGINE ---
class JobFeedScreen extends StatefulWidget {
  const JobFeedScreen({super.key});
  @override
  State<JobFeedScreen> createState() => _JobFeedScreenState();
}

class _JobFeedScreenState extends State<JobFeedScreen> {
  final List<JobPost> _allJobs = [
    JobPost(title: "Data Analyst", company: "Google", location: "Hyderabad", mode: "Hybrid", salary: "25L", match: "98%", sector: "MNC"),
    JobPost(title: "Python Lead", company: "Meta", location: "Bangalore", mode: "Remote", salary: "18L", match: "95%", sector: "MNC"),
    JobPost(title: "Fullstack Dev", company: "Zepto", location: "Mumbai", mode: "On-site", salary: "22L", match: "94%", sector: "Unicorn"),
    JobPost(title: "System Eng", company: "TCS", location: "Pune", mode: "Hybrid", salary: "12L", match: "88%", sector: "IT Services"),
    JobPost(title: "ML Expert", company: "Mistral AI", location: "Chennai", mode: "Remote", salary: "30L", match: "99%", sector: "Startup"),
  ];
  List<JobPost> _filtered = [];
  @override
  void initState() { super.initState(); _filtered = _allJobs; }

  void _runAdvancedFilter(String q) {
    setState(() => _filtered = _allJobs.where((j) => 
      j.title.toLowerCase().contains(q.toLowerCase()) || 
      j.location.toLowerCase().contains(q.toLowerCase()) || 
      j.mode.toLowerCase().contains(q.toLowerCase()) ||
      j.sector.toLowerCase().contains(q.toLowerCase())).toList());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Smart Priority Search")),
    body: Column(
      children: [
        Padding(padding: const EdgeInsets.all(12), child: TextField(onChanged: _runAdvancedFilter, decoration: InputDecoration(hintText: "Search Locations, Work Mode, MNCs...", prefixIcon: const Icon(Icons.search, color: Color(0xFF2DD4BF)), filled: true, fillColor: Colors.white10, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)))),
        // Persistent Filter Row
        SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
          UIHelper.filterChip("Hyderabad"), UIHelper.filterChip("Remote"), UIHelper.filterChip("MNC"), UIHelper.filterChip("Hybrid"), UIHelper.filterChip("All India"),
        ])),
        Expanded(child: ListView.builder(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(16), itemCount: _filtered.length, itemBuilder: (c, i) => _buildCard(_filtered[i]))),
      ],
    ),
  );

  Widget _buildCard(JobPost j) => Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(j.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), UIHelper.badge(j.match)]),
      Text("${j.company} • ${j.location} • ${j.mode}", style: const TextStyle(color: Colors.white38)),
      const SizedBox(height: 10),
      Text(j.sector, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)),
      const SizedBox(height: 20),
      ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), minimumSize: const Size(double.infinity, 45)), onPressed: () => UIHelper.showRTR(context), child: const Text("Quick Apply")),
    ]));
}

// --- TAB 5: CATEGORIZED ACCOUNT DASHBOARD ---
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("My Profile")),
    body: SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(24), child: Column(children: [
      Stack(alignment: Alignment.bottomRight, children: const [CircleAvatar(radius: 40, child: Icon(Icons.person)), Icon(Icons.verified, color: Colors.blue, size: 28)]),
      const SizedBox(height: 10), const Text("Sujith Reddy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      const Divider(height: 40),
      _pBox("Basic Details", [UIHelper.row("DOB", "25 Dec 2002"), UIHelper.row("Location", "Hyderabad")]),
      _pBox("Educational Details", [UIHelper.row("Degree", "B.Tech CSE"), UIHelper.row("College", "IIT Hyderabad")]),
      _pBox("Professional Details", [UIHelper.row("Primary Skill", "Python"), UIHelper.row("Experience", "2.5 Years")]),
      _pBox("Sports & Activities", [UIHelper.row("Sport", "Cricket (Leg Spinner)"), UIHelper.row("Academy", "Legala Academy")]),
      _pBox("Certifications", [
        UIHelper.row("AI Mastery", "Verified"),
        TextButton(onPressed: (){}, child: const Text("+ Learn & Add New Certificates", style: TextStyle(color: Color(0xFF2DD4BF)))),
      ]),
      const Divider(height: 40),
      UIHelper.fBtn(context, "AI Resume Builder", Icons.auto_fix_high, Colors.teal),
      UIHelper.fBtn(context, "Upload Resume (PDF)", Icons.upload_file, Colors.blue),
      UIHelper.fBtn(context, "Verify Govt ID", Icons.badge, Colors.purpleAccent),
      const SizedBox(height: 20),
ListTile(
  leading: const Icon(Icons.logout, color: Colors.redAccent),
  title: const Text("Sign Out"),
  onTap: () async {
    await Supabase.instance.client.auth.signOut();
  },
),
    ])),
  );

  Widget _pBox(String t, List<Widget> items) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text(t, style: const TextStyle(color: Color(0xFF2DD4BF), fontWeight: FontWeight.bold))),
    Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(15)), child: Column(children: items)),
  ]);
}

// --- TAB 3: TRUST BREAKDOWN (FIXED PERMANENTLY) ---
class TrustBreakdownScreen extends StatelessWidget {
  const TrustBreakdownScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text("Trust Score")),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
      Container(padding: const EdgeInsets.all(30), width: double.infinity, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0D9488), Color(0xFF2DD4BF)]), borderRadius: BorderRadius.circular(20)), child: Column(children: const [Text("SCORE"), Text("850", style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)), Text("Verified in Telangana")])),
      const SizedBox(height: 30),
      UIHelper.tBar("Identity Check", 1.0, Colors.blue), UIHelper.tBar("Skill Integrity", 0.85, Colors.teal),
      UIHelper.tBar("RTR Data Consistency", 0.95, Colors.orange),
    ])),
  );
}

// --- UI HELPERS ---
class UIHelper {
  static Widget badge(String t) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Text(t, style: const TextStyle(color: Color(0xFF2DD4BF), fontSize: 11, fontWeight: FontWeight.bold)));
  static Widget filterChip(String label) => Padding(padding: const EdgeInsets.only(right: 8), child: Chip(label: Text(label, style: const TextStyle(fontSize: 12)), backgroundColor: Colors.white10));
  static Widget inputField(String h, {IconData? icon, bool obscure = false}) => Padding(padding: const EdgeInsets.only(top: 15), child: TextField(obscureText: obscure, decoration: InputDecoration(labelText: h, prefixIcon: Icon(icon), border: const OutlineInputBorder())));
  static Widget row(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(l, style: const TextStyle(color: Colors.white38)), Text(v)]));
  static Widget fBtn(BuildContext c, String l, IconData i, Color col) => Card(child: ListTile(leading: Icon(i, color: col), title: Text(l), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.push(c, MaterialPageRoute(builder: (c) => Scaffold(appBar: AppBar(title: Text(l)), body: const Center(child: Text("Service Active")))))));
  static Widget tBar(String l, double v, Color c) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(l), const SizedBox(height: 8), LinearProgressIndicator(value: v, color: c, minHeight: 8)]));
  static Widget statusCard(String c, String s, Color col) => Card(child: ListTile(title: Text(c, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(s, style: TextStyle(color: col))));
  static void showRTR(BuildContext context) => showModalBottomSheet(context: context, isScrollControlled: true, builder: (c) => const RTRStepper());
  static void showForgotPass(BuildContext context) => showModalBottomSheet(context: context, backgroundColor: const Color(0xFF0F172A), builder: (c) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text("Reset Password"), UIHelper.inputField("Email/Phone"), const SizedBox(height: 20), ElevatedButton(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success: Reset link sent!"))); }, child: const Text("Send Link")), const SizedBox(height: 30)])));
}

// --- POPULATED ALERTS & TRACKER ---
class NotificationScreen extends StatelessWidget { const NotificationScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Smart Alerts")), body: ListView(padding: const EdgeInsets.all(16), children: const [ListTile(leading: Icon(Icons.bolt, color: Colors.amber), title: Text("98% Match!"), subtitle: Text("Google posted a new Python role."))])); }
class TrackerScreen extends StatelessWidget { const TrackerScreen({super.key}); @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text("Tracker")), body: ListView(padding: const EdgeInsets.all(16), children: [UIHelper.statusCard("Google", "Technical Phase", Colors.green)])); }

// --- RTR AUTO-APPLY STEPPER ---
class RTRStepper extends StatefulWidget {
  const RTRStepper({super.key});
  @override
  State<RTRStepper> createState() => _RTRStepperState();
}

class _RTRStepperState extends State<RTRStepper> {
  int _step = 0;
  @override
  Widget build(BuildContext context) => Container(height: MediaQuery.of(context).size.height * 0.85, padding: const EdgeInsets.all(20), child: Column(children: [
    const Text("RTR Confirmation", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    Expanded(child: Stepper(currentStep: _step, onStepContinue: () { if (_step < 4) {
      setState(() => _step++);
    } else {
      Navigator.pop(context);
    } }, steps: [
      Step(title: const Text("Experience"), content: Column(children: [UIHelper.inputField("T.exp"), UIHelper.inputField("R.exp")])),
      Step(title: const Text("Location"), content: Column(children: [UIHelper.inputField("C.location"), UIHelper.inputField("P.location")])),
      Step(title: const Text("Financials"), content: Column(children: [UIHelper.inputField("C.ctc"), UIHelper.inputField("E.ctc")])),
      Step(title: const Text("Notice"), content: UIHelper.inputField("Notice Period")),
      Step(title: const Text("Pipeline"), content: UIHelper.inputField("Offers in hand?")),
    ])),
  ]));
}