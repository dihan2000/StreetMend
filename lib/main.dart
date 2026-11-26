import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'brand.dart';

import 'theme/appearance_controller.dart';
import 'theme/appearance_store.dart';
import 'theme/appearance_scope.dart';
import 'theme/streetmend_theme.dart';
import 'profile/profile_page.dart';
import 'capture/capture_page.dart';
import 'capture/services/photo_service.dart';
import 'reports/report.dart';
import 'reports/my_reports_page.dart';
import 'reports/report_details_page.dart';

/// Flutter always starts here. runApp() shows the root widget.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appearance = AppearanceController(LocalAppearanceStore());
  await appearance.load();
  runApp(StreetMendApp(appearance: appearance));
}

/// Rebuilds the theme without replacing the Navigator or page state.
class StreetMendApp extends StatefulWidget {
  const StreetMendApp({super.key, this.appearance, this.home});
  final AppearanceController? appearance;
  final Widget? home;
  @override
  State<StreetMendApp> createState() => _StreetMendAppState();
}

class _StreetMendAppState extends State<StreetMendApp> {
  late final _appearance =
      widget.appearance ?? AppearanceController(LocalAppearanceStore());
  @override
  void dispose() {
    if (widget.appearance == null) _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppearanceScope(
    controller: _appearance,
    child: ListenableBuilder(
      listenable: _appearance,
      builder: (context, _) => MaterialApp(
        title: 'StreetMend',
        debugShowCheckedModeBanner: false,
        theme: StreetMendTheme.light,
        darkTheme: StreetMendTheme.dark,
        themeMode: _appearance.mode,
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: child!,
        ),
        home: widget.home ?? const StreetMendSplashPage(),
      ),
    ),
  );
}

/// Opens the existing home screen. Used until real auth screens exist.
void openHomeScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const StreetMendHomePage()),
  );
}

/// Opens the login form. Used by the Welcome screen Log In button.
void openLoginScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const StreetMendLoginPage()),
  );
}

/// Brief branded launch screen. Fades in, then replaces itself with Welcome.
class StreetMendSplashPage extends StatefulWidget {
  const StreetMendSplashPage({super.key});

  @override
  State<StreetMendSplashPage> createState() => _StreetMendSplashPageState();
}

class _StreetMendSplashPageState extends State<StreetMendSplashPage>
    with SingleTickerProviderStateMixin {
  // AnimationController needs vsync from SingleTickerProviderStateMixin.
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    // Start the fade as soon as this screen appears.
    _fadeController.forward();

    // After about 2 seconds, move to Welcome and remove Splash from history.
    Future.delayed(const Duration(milliseconds: 2000), _goToWelcome);
  }

  void _goToWelcome() {
    // mounted is false if the user already left this screen.
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const StreetMendWelcomePage()),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: appColors(context).panel,
        body: Stack(
          children: [
            // Soft teal shapes give a blurred, premium feel without extra packages.
            Positioned(
              top: -80,
              right: -40,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kFreshTeal.withValues(alpha: 0.35),
                      kFreshTeal.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      kFreshTeal.withValues(alpha: 0.28),
                      kFreshTeal.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 180,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kFreshTeal.withValues(alpha: 0.10),
                ),
              ),
            ),
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const StreetMendMark(size: 112, onDark: true),
                      const SizedBox(height: 24),
                      const Text(
                        'StreetMend',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Better streets, together.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Built-in StreetMend mark: a street pin on a rounded navy tile.
/// No image files or extra packages are needed.
class StreetMendMark extends StatelessWidget {
  const StreetMendMark({super.key, this.size = 64, this.onDark = false});

  final double size;
  // Light tile for the navy splash so the logo stays visible.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onDark ? Colors.white : kOceanNavy,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft teal glow behind the pin.
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: const BoxDecoration(
              color: kFreshTeal,
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: size * 0.42,
          ),
          // Gold bar suggests a street under the pin.
          Positioned(
            bottom: size * 0.16,
            child: Container(
              width: size * 0.38,
              height: size * 0.07,
              decoration: BoxDecoration(
                color: kWarmGold,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Welcome / onboarding screen. Shown after the splash.
class StreetMendWelcomePage extends StatelessWidget {
  const StreetMendWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors(context).background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Brand row at the top.
              Row(
                children: [
                  const StreetMendMark(size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Street',
                            style: TextStyle(
                              color: appColors(context).ink,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: 'Mend',
                            style: TextStyle(
                              color: appColors(context).accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      style: const TextStyle(fontSize: 22, letterSpacing: -0.4),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Scrollable middle so smaller iPhones do not overflow.
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const StreetMendHero(),
                      const SizedBox(height: 28),
                      Text(
                        'A better street starts with you.',
                        style: TextStyle(
                          fontSize: 34,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          color: appColors(context).ink,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'See It. Report It. Mend It.',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: appColors(context).accent,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Spot a pothole, broken light, damaged sign, faulty signal, or blocked drain. Report it in moments and help keep streets safer.',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.45,
                          color: appColors(context).body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Actions stay near the thumb at the bottom.
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => openHomeScreen(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kFreshTeal,
                  foregroundColor: kOceanNavy,
                  elevation: 0,
                  minimumSize: const Size.fromHeight(56),
                  textStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text('Get Started'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => openLoginScreen(context),
                style: TextButton.styleFrom(
                  foregroundColor: appColors(context).ink,
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Log In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Login form. Checks the fields, but does not sign the user in yet.
class StreetMendLoginPage extends StatefulWidget {
  const StreetMendLoginPage({super.key});

  @override
  State<StreetMendLoginPage> createState() => _StreetMendLoginPageState();
}

class _StreetMendLoginPageState extends State<StreetMendLoginPage> {
  // FormState lets us run all field validators with one button tap.
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hidePassword = true;

  @override
  void dispose() {
    // Controllers must be disposed so they do not keep using memory.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: appColors(context).panel,
      ),
    );
  }

  /// Returns an error string, or null when the email looks OK.
  String? _validateEmail(String? value) {
    final email = (value ?? '').trim();
    if (email.isEmpty) {
      return 'Please enter your email address.';
    }
    // Simple beginner check: an @ and a . are required. Not full email rules.
    if (!email.contains('@') || !email.contains('.')) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').isEmpty) {
      return 'Please enter your password.';
    }
    return null;
  }

  void _onSignIn() {
    // validate() runs every TextFormField validator.
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    _showMessage('Authentication will be connected to Supabase later.');
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: appColors(context).ink),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: appColors(context).surface,
      labelStyle: TextStyle(color: appColors(context).body),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: appColors(context).soft, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: appColors(context).accent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: appColors(context).error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: appColors(context).error, width: 1.8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors(context).background,
      // Ivory app bar keeps the back arrow, without the navy Home toolbar.
      appBar: AppBar(
        backgroundColor: appColors(context).background,
        foregroundColor: appColors(context).ink,
        systemOverlayStyle: appColors(context).dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        elevation: 0,
      ),
      // true (default) lifts the page when the iPhone keyboard opens.
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: StreetMendMark(size: 72)),
                const SizedBox(height: 16),
                Text(
                  'Welcome back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: appColors(context).ink,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue reporting street issues.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: appColors(context).body,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: _validateEmail,
                  decoration: _fieldDecoration(
                    label: 'Email address',
                    icon: Icons.mail_outline,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _hidePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _onSignIn(),
                  validator: _validatePassword,
                  decoration: _fieldDecoration(
                    label: 'Password',
                    icon: Icons.lock_outline,
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () {
                        setState(() {
                          _hidePassword = !_hidePassword;
                        });
                      },
                      icon: Icon(
                        _hidePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: appColors(context).ink,
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showMessage('Coming Soon'),
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: appColors(context).accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _onSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kFreshTeal,
                    foregroundColor: kOceanNavy,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(56),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => _showMessage('Coming Soon'),
                  child: Text(
                    'Create Account',
                    style: TextStyle(
                      color: appColors(context).ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Original hero graphic made from Flutter shapes and icons.
/// It suggests a street and a report pin without using maps or images.
class StreetMendHero extends StatelessWidget {
  const StreetMendHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: appColors(context).soft,
        borderRadius: BorderRadius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Soft decorative circles for depth.
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -36,
            left: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: appColors(context).accent.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const StreetMendMark(size: 72),
                const SizedBox(height: 18),
                // Simple street path with a gold highlight stripe.
                Container(
                  width: 168,
                  height: 18,
                  decoration: BoxDecoration(
                    color: appColors(context).ink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 110,
                    height: 4,
                    decoration: BoxDecoration(
                      color: kWarmGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Report what you see nearby',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: appColors(context).ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Home dashboard. Stateful so the bottom tab highlight can change.
class StreetMendHomePage extends StatefulWidget {
  const StreetMendHomePage({super.key});

  @override
  State<StreetMendHomePage> createState() => _StreetMendHomePageState();
}

class _StreetMendHomePageState extends State<StreetMendHomePage> {
  // Home and Reports share this tab bar. Other features are coming soon.
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _recoverPhoto();
  }

  Future<void> _recoverPhoto() async {
    try {
      final photo = await PhotoService().recover();
      if (!mounted || photo == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => CapturePage(recoveredPhoto: photo),
          ),
        );
      });
    } catch (_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'The previous photo could not be recovered. Please select it again in Capture.',
            ),
          ),
        );
      });
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Coming Soon'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: appColors(context).panel,
      ),
    );
  }

  void _onTabTap(int index) {
    if (index == 2) {
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const CapturePage()));
      return;
    }
    if (index == 0 || index == 1 || index == 4) {
      setState(() => _tabIndex = index);
      return;
    }
    _showComingSoon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors(context).background,
      body: IndexedStack(
        index: _tabIndex == 4 ? 2 : _tabIndex,
        children: [
          Column(
            children: [
              HomeHeroHeader(onNotificationTap: _showComingSoon),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pulls the report card up onto the curved hero.
                      Transform.translate(
                        offset: const Offset(0, -28),
                        child: CurrentReportCard(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ReportDetailsPage(
                                report: sampleReports.first,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Explore StreetMend',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: appColors(context).ink,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find reports, rewards, and help nearby.',
                        style: TextStyle(
                          fontSize: 13,
                          color: appColors(context).body,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ExploreGrid(
                        onTap: _showComingSoon,
                        onReportsTap: () => _onTabTap(1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const MyReportsPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: StreetMendTabBar(
        currentIndex: _tabIndex,
        onTap: _onTabTap,
      ),
    );
  }
}

/// Navy gradient header with greeting, points, and notifications.
class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({super.key, required this.onNotificationTap});

  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 10, 20, 48),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: appColors(context).heroGradient,
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -30,
              right: -10,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kFreshTeal.withValues(alpha: 0.16),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 80,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kFreshTeal, width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0xFF2A5A6A),
                        child: Text(
                          'D',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              color: Color(0xFFB7D4DA),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Hello, Dihan!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: onNotificationTap,
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: kWarmGold.withValues(alpha: 0.55),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.stars_rounded, color: kWarmGold, size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '1,240 Street Points',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Large navy card for the user's most important open report.
class CurrentReportCard extends StatelessWidget {
  const CurrentReportCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: appColors(context).heroGradient,
            ),
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: kOceanNavy.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  Text(
                    'CURRENT REPORT',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.62),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: kWarmGold,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'In Progress',
                      style: TextStyle(
                        color: kOceanNavy,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: kFreshTeal,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Broken Streetlight',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: kFreshTeal,
                              size: 16,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Jalan Teknokrat',
                                style: TextStyle(
                                  color: Color(0xFFD5E8EC),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              color: Color(0xFFD5E8EC),
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '18 Oct 2026',
                                style: TextStyle(
                                  color: Color(0xFFD5E8EC),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Eight shortcut tiles in a 4-by-2 grid, sized for iPhone widths.
class ExploreGrid extends StatelessWidget {
  const ExploreGrid({
    super.key,
    required this.onTap,
    required this.onReportsTap,
  });

  final VoidCallback onReportsTap;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final items = <({IconData icon, String label, Color fill, Color tint})>[
      (
        icon: Icons.near_me_rounded,
        label: 'Nearby',
        fill: const Color(0xFFE7F4F2),
        tint: kFreshTeal,
      ),
      (
        icon: Icons.assignment_rounded,
        label: 'Reports',
        fill: const Color(0xFFE8F1F5),
        tint: kOceanNavy,
      ),
      (
        icon: Icons.leaderboard_rounded,
        label: 'Ranks',
        fill: const Color(0xFFFFF4DC),
        tint: const Color(0xFFC7922A),
      ),
      (
        icon: Icons.verified_rounded,
        label: 'Verified',
        fill: const Color(0xFFE4F6F2),
        tint: kFreshTeal,
      ),
      (
        icon: Icons.notifications_active_rounded,
        label: 'Alerts',
        fill: const Color(0xFFE8EEF3),
        tint: kOceanNavy,
      ),
      (
        icon: Icons.map_rounded,
        label: 'Map',
        fill: kMistBlue,
        tint: const Color(0xFF2F6F7C),
      ),
      (
        icon: Icons.card_giftcard_rounded,
        label: 'Rewards',
        fill: const Color(0xFFFFF1D4),
        tint: const Color(0xFFC7922A),
      ),
      (
        icon: Icons.help_rounded,
        label: 'Help',
        fill: const Color(0xFFEEF3F6),
        tint: kOceanNavy,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 12,
      crossAxisSpacing: 10,
      mainAxisExtent: 110 + (MediaQuery.textScalerOf(context).scale(11) - 11),
      children: [
        for (final item in items)
          ExploreTile(
            icon: item.icon,
            label: item.label,
            fill: item.fill,
            tint: item.tint,
            onTap: item.label == 'Reports' ? onReportsTap : onTap,
          ),
      ],
    );
  }
}

class ExploreTile extends StatelessWidget {
  const ExploreTile({
    super.key,
    required this.icon,
    required this.label,
    required this.fill,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color fill;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: appColors(context).surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            color: appColors(context).surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kOceanNavy.withValues(alpha: 0.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: appColors(context).dark
                      ? appColors(context).soft
                      : fill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: appColors(context).dark
                      ? appColors(context).accent
                      : tint,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: appColors(context).ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom iOS-style tab bar. Capture is the raised centre action.
class StreetMendTabBar extends StatelessWidget {
  const StreetMendTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(
        8,
        10,
        8,
        bottomInset > 0 ? bottomInset : 10,
      ),
      decoration: BoxDecoration(
        color: appColors(context).surface,
        boxShadow: [
          BoxShadow(
            color: kOceanNavy.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Home',
            selected: currentIndex == 0,
            onTap: () => onTap(0),
          ),
          _NavItem(
            icon: Icons.assignment_outlined,
            label: 'Reports',
            selected: currentIndex == 1,
            onTap: () => onTap(1),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTap(2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: kFreshTeal,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: kFreshTeal.withValues(alpha: 0.40),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: kOceanNavy,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capture',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: currentIndex == 2
                          ? appColors(context).accent
                          : appColors(context).ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _NavItem(
            icon: Icons.card_giftcard_rounded,
            label: 'Rewards',
            selected: currentIndex == 3,
            onTap: () => onTap(3),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profile',
            selected: currentIndex == 4,
            onTap: () => onTap(4),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? appColors(context).accent
        : appColors(context).muted;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
