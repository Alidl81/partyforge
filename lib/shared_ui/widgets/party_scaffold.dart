import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PartyBackButton extends StatelessWidget {
  const PartyBackButton({super.key, required this.fallbackLocation});

  final String fallbackLocation;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'بازگشت',
      icon: const BackButtonIcon(),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(fallbackLocation);
        }
      },
    );
  }
}

class PartyScaffold extends StatelessWidget {
  const PartyScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.fallbackLocation,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
  });

  final String title;
  final Widget body;
  final String fallbackLocation;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) context.go(fallbackLocation);
      },
      child: Scaffold(
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: PartyBackButton(fallbackLocation: fallbackLocation),
          title: Text(title),
          actions: actions,
        ),
        body: body,
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
