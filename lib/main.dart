import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'config/otpless_config.dart';
import 'otpless/otpless_service.dart';
import 'screens/login_page.dart';
import 'screens/otp_page.dart';
import 'screens/setup_required_page.dart';
import 'screens/success_page.dart';
import 'screens/waiting_page.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = await OtplessConfig.load();
  runApp(OtplessDemoApp(config: config));
}

class OtplessDemoApp extends StatelessWidget {
  const OtplessDemoApp({super.key, required this.config});

  final OtplessConfig config;

  @override
  Widget build(BuildContext context) {
    ThemeData theme(Brightness b) => ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF84C225), brightness: b),
          inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder()),
        );

    return MaterialApp(
      title: 'BigBasket × OTPLESS',
      debugShowCheckedModeBanner: false,
      theme: theme(Brightness.light),
      darkTheme: theme(Brightness.dark),
      home: config.isConfigured
          ? AuthShell(appId: config.appId)
          : const SetupRequiredPage(),
    );
  }
}

/// Hosts the sign-in flow and swaps pages based on [AuthController.step].
class AuthShell extends StatefulWidget {
  const AuthShell({super.key, required this.appId});

  final String appId;

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell> {
  final _controller = AuthController();

  @override
  void initState() {
    super.initState();
    // Initialize once, when the first screen that needs OTPLESS appears.
    OtplessService.instance.initialize(widget.appId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final step = _controller.step;
        final inFlow =
            step == AuthStep.verifyOtp || step == AuthStep.waiting;

        return PopScope(
          // Back from OTP / waiting returns to the first step instead of
          // closing the app.
          canPop: !inFlow,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) _controller.reset();
          },
          child: Scaffold(
            appBar: AppBar(
              title: const Text('BigBasket × OTPLESS'),
              leading: inFlow
                  ? BackButton(onPressed: _controller.reset)
                  : null,
              actions: const [SdkStatusChip()],
            ),
            body: SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(step),
                  child: switch (step) {
                    AuthStep.enterIdentity =>
                      LoginPage(controller: _controller),
                    AuthStep.verifyOtp => OtpPage(controller: _controller),
                    AuthStep.waiting => WaitingPage(controller: _controller),
                    AuthStep.authenticated =>
                      SuccessPage(controller: _controller),
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
