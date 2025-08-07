import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimatedSplashScreen extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedSplashScreen({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _fadeController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Logo scale animation (bounce effect)
    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Logo rotation animation (subtle rotation)
    _logoRotation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    // Fade out animation
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _startAnimation();
  }

  void _startAnimation() async {
    // Start logo animation
    await _logoController.forward();
    
    // Wait a bit before starting fade out
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Start fade out
    await _fadeController.forward();
    
    // Navigate to main app
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => widget.child,
          transitionDuration: const Duration(milliseconds: 300),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: Listenable.merge([_logoController, _fadeController]),
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8F9FA),
                    Color(0xFFFFFFFF),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated Logo
                  Transform.scale(
                    scale: _logoScale.value,
                    child: Transform.rotate(
                      angle: _logoRotation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/logo/app_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // App Name with typewriter effect
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoController.value,
                        child: const Text(
                          'SDG Network',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            letterSpacing: 2,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Subtitle
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoController.value * 0.8,
                        child: const Text(
                          'Business Sustainability',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF666666),
                            letterSpacing: 1,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _logoController.value,
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF2E7D32).withOpacity(0.7),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
