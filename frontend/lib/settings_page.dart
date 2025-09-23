import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'theme/app_theme.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInDown(
            duration: const Duration(milliseconds: 600),
            child: Text(
              'Settings',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          FadeInDown(
            duration: const Duration(milliseconds: 700),
            child: Text(
              'Customize your YOLOFusion experience',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeInUp(
            duration: const Duration(milliseconds: 800),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.account_circle,
                        color: AppTheme.primaryBlue,
                      ),
                      title: Text(
                        'Account',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onTap: () {
                        // Navigate to Account Settings
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.notifications,
                        color: AppTheme.primaryBlue,
                      ),
                      title: Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onTap: () {
                        // Navigate to Notification Settings
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.privacy_tip,
                        color: AppTheme.primaryBlue,
                      ),
                      title: Text(
                        'Privacy',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      onTap: () {
                        // Navigate to Privacy Settings
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}