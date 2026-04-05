import 'package:flutter/material.dart';

import '../../theme/content_spacing.dart';
import '../../widgets/common/bc_app_bar.dart';
import './commissions/commissions_screen.dart';
import './messages/messages_screen.dart';

class CommunicationScreen extends StatefulWidget {
  /// 0 = Messages, 1 = Commissions
  final int initialTabIndex;

  const CommunicationScreen({super.key, this.initialTabIndex = 0});

  @override
  State<CommunicationScreen> createState() => _CommunicationScreenState();
}

class _CommunicationScreenState extends State<CommunicationScreen> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex.clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFF4A4A);

    return Scaffold(
      appBar: const BcAppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                kScreenHorizontalPadding,
                8 + kContentBelowAppBarPadding,
                kScreenHorizontalPadding,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      backgroundColor: _selectedTab == 0 ? accent : Colors.white,
                      textColor: _selectedTab == 0 ? Colors.white : Colors.black,
                      label: 'Messages',
                      isActive: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TabButton(
                      backgroundColor: _selectedTab == 1 ? accent : Colors.white,
                      textColor: _selectedTab == 1 ? Colors.white : Colors.black,
                      label: 'Commissions',
                      isActive: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedTab == 0
                  ? const _MessagesScreenContent()
                  : const _CommissionsScreenContent(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.backgroundColor,
    required this.textColor,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagesScreenContent extends StatelessWidget {
  const _MessagesScreenContent();

  @override
  Widget build(BuildContext context) {
    return MessagesScreen();
  }
}

class _CommissionsScreenContent extends StatelessWidget {
  const _CommissionsScreenContent();

  @override
  Widget build(BuildContext context) {
    return CommissionsScreen();
  }
}
