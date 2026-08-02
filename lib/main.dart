import 'package:pro_recruit_ai/shared/app_design_system.dart';
import 'package:pro_recruit_ai/shared/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'package:pro_recruit_ai/features/candidate/candidate_root.dart';
import 'package:pro_recruit_ai/features/candidate/screens/candidate_onboarding_screen.dart';
import 'package:pro_recruit_ai/features/recruiter/recruiter_root.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: "assets/.env");

  String rawUrl = dotenv.get('SUPABASE_URL', fallback: "");
  String rawKey = dotenv.get('SUPABASE_ANON_KEY', fallback: "");

  String cleanUrl = rawUrl.replaceAll("'", "").replaceAll('"', "").replaceAll(',', "").trim();
  String cleanKey = rawKey.replaceAll("'", "").replaceAll('"', "").replaceAll(',', "").trim();

  await Supabase.initialize(
    url: cleanUrl,
    anonKey: cleanKey,
  );

  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("fc16b84a-85ff-4fce-b472-debcd8bb09e3");
  OneSignal.Notifications.requestPermission(true);

  runApp(const HyloApp());
}

class HyloApp extends StatefulWidget {
  const HyloApp({super.key});

  @override
  State<HyloApp> createState() => _HyloAppState();
}

class _HyloAppState extends State<HyloApp> {
  @override
  void initState() {
    super.initState();
    ThemeController.instance.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeController.instance.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: ValueKey(ThemeController.instance.isDarkMode),
      debugShowCheckedModeBanner: false,
      title: 'Hylo',
      theme: AppTheme.light,
      home: const AuthGateController(),
    );
  }
}

// --- 🛡️ AUTH GATE ---
class AuthGateController extends StatelessWidget {
  const AuthGateController({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = snapshot.data?.session ?? Supabase.instance.client.auth.currentSession;
        if (session == null) return const AuthWelcomeScreen();

        return FutureBuilder<PostgrestMap?>(
          future: Supabase.instance.client
              .from('profiles')
              .select('user_role, onboarding_completed')
              .eq('id', session.user.id)
              .maybeSingle(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final role = snap.data?['user_role'] ?? 'candidate';
            if (role == 'recruiter') return const RecruiterRoot();
            final onboardingDone = snap.data?['onboarding_completed'] == true;
            return onboardingDone ? const CandidateRoot() : const CandidateOnboardingScreen();
          },
        );
      },
    );
  }
}

// --- ⏱️ SPLASH ---
class EngineSplashView extends StatefulWidget {
  const EngineSplashView({super.key});
  @override
  State<EngineSplashView> createState() => _EngineSplashViewState();
}

class _EngineSplashViewState extends State<EngineSplashView> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _ctrl,
              builder: (context, _) => Transform.rotate(
                angle: _ctrl.value * 2 * math.pi,
                child: CustomPaint(size: const Size(80, 80), painter: AshWheelPainter()),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text("Hylo", style: GoogleFonts.lobster(fontSize: 40, color: AppColors.textLight)),
          ],
        ),
      ),
    );
  }
}

// --- 📱 WELCOME SCREEN ---
class AuthWelcomeScreen extends StatefulWidget {
  const AuthWelcomeScreen({super.key});
  @override
  State<AuthWelcomeScreen> createState() => _AuthWelcomeScreenState();
}

class _AuthWelcomeScreenState extends State<AuthWelcomeScreen> with SingleTickerProviderStateMixin {
  bool isRecruiter = false;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: AppSpacing.xxxl),
                    CustomPaint(size: const Size(90, 90), painter: AshWheelPainter()),
                    SizedBox(height: AppSpacing.lg),
                    Text("Hylo", style: GoogleFonts.lobster(fontSize: 64, color: AppColors.textLight)),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      "Premium Hiring Ecosystem",
                      style: AppTypography.bodySmall.copyWith(color: Colors.white70, letterSpacing: 1.5),
                    ),
                    SizedBox(height: AppSpacing.xxxl + AppSpacing.md),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        minimumSize: Size(w * 0.82, 54),
                        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => LoginScreen(isRecruiter: isRecruiter))),
                      child: Text(
                        isRecruiter ? "Enter Recruiter Console" : "Explore Opportunities",
                        style: AppTypography.bodyMediumBold.copyWith(color: AppColors.primary, fontSize: 15),
                      ),
                    ),
                    SizedBox(height: AppSpacing.lg),
                    TextButton(
                      onPressed: () => setState(() => isRecruiter = !isRecruiter),
                      child: Text(
                        "Switch to ${isRecruiter ? 'Candidate' : 'Recruiter'} Mode",
                        style: AppTypography.bodySmallBold.copyWith(color: Colors.white70),
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxxl + AppSpacing.md),
                    Text(
                      "MADE IN TELANGANA",
                      style: AppTypography.captionBold.copyWith(color: AppColors.textLight, letterSpacing: 2),
                    ),
                    SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 🔐 LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  final bool isRecruiter;
  const LoginScreen({super.key, required this.isRecruiter});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isSignUp = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final client = Supabase.instance.client;
    try {
      if (_isSignUp) {
        final res = await client.auth.signUp(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
          data: {
            'user_role': widget.isRecruiter ? 'recruiter' : 'candidate',
            'full_name': _nameCtrl.text.trim(),
          },
        );
        if (res.user != null) {
          OneSignal.login(res.user!.id);
          await Future.delayed(const Duration(milliseconds: 500));
          try {
            await client.from('profiles').upsert({
              'id': res.user!.id,
              'full_name': _nameCtrl.text.trim(),
              'user_role': widget.isRecruiter ? 'recruiter' : 'candidate',
            });
          } catch (e) {
            debugPrint('Profile error: $e');
          }
        }
      } else {
        final signInRes = await client.auth.signInWithPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
        if (signInRes.user != null) {
          OneSignal.login(signInRes.user!.id);
        }
      }
      if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
    } on AuthException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.warning));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _socialLogin(OAuthProvider p) async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        p,
        redirectTo: 'io.supabase.flutter://callback',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("OAuth Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("OAuth Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl + AppSpacing.xs, vertical: AppSpacing.sm),
          child: SizedBox(
            width: w > 600 ? 440 : w * 0.88,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isSignUp ? "Create Account" : "Welcome Back",
                    style: AppTypography.headlineLarge.copyWith(color: AppColors.textLight, fontSize: 32),
                  ),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.isRecruiter ? "RECRUITER ENGINE" : "CANDIDATE PORTAL",
                    style: AppTypography.captionBold.copyWith(color: Colors.white54, letterSpacing: 1.5),
                  ),
                  SizedBox(height: AppSpacing.xxl + AppSpacing.xs),
                  if (_isSignUp)
                    _field("Full Name", Icons.person_outline, _nameCtrl,
                        validator: (v) => v!.isEmpty ? "Name is required" : null),
                  _field(
                    "Corporate Email",
                    Icons.email_outlined,
                    _emailCtrl,
                    validator: (v) => v!.contains('@') ? null : "Invalid email",
                  ),
                  _field(
                    "Password",
                    Icons.lock_outline,
                    _passCtrl,
                    obs: true,
                    validator: (v) => v!.length >= 6 ? null : "Min 6 characters",
                  ),
                  SizedBox(height: AppSpacing.xl + AppSpacing.xs),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.medium),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5))
                        : Text(
                            _isSignUp ? "CREATE ACCOUNT" : "LOGIN",
                            style: AppTypography.bodyMediumBold.copyWith(color: AppColors.primary, fontSize: 14),
                          ),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Center(
                    child: TextButton(
                      onPressed: () => setState(() => _isSignUp = !_isSignUp),
                      child: Text(
                        _isSignUp ? "Already have an account? Login" : "Don't have an account? Sign Up",
                        style: AppTypography.bodySmall.copyWith(color: Colors.white70),
                      ),
                    ),
                  ),
                  const Divider(color: Colors.white24, height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _oauthBtn(Icons.g_mobiledata, "Google", () => _socialLogin(OAuthProvider.google)),
                      SizedBox(width: AppSpacing.xl),
                      _oauthBtn(Icons.link, "LinkedIn", () => _socialLogin(OAuthProvider.linkedin)),
                    ],
                  ),
                  SizedBox(height: AppSpacing.xxl + AppSpacing.md),
                  Center(
                    child: Text(
                      "MADE IN TELANGANA",
                      style: AppTypography.captionBold.copyWith(color: AppColors.textLight, letterSpacing: 2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    IconData icon,
    TextEditingController c, {
    bool obs = false,
    String? Function(String?)? validator,
  }) =>
      Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: TextFormField(
          controller: c,
          obscureText: obs,
          validator: validator,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textLight),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.white70, size: 20),
            hintText: label,
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.08),
            border: OutlineInputBorder(borderRadius: AppBorderRadius.medium, borderSide: BorderSide.none),
            errorStyle: const TextStyle(color: Colors.orangeAccent),
          ),
        ),
      );

  Widget _oauthBtn(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: AppBorderRadius.small,
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 22),
              SizedBox(width: AppSpacing.sm),
              Text(label, style: AppTypography.bodySmallBold.copyWith(color: AppColors.textLight)),
            ],
          ),
        ),
      );
}
