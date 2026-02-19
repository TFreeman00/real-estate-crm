import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'features/contacts/data/repositories/contact_repository.dart';
import 'features/contacts/presentation/providers/contacts_provider.dart';
import 'features/contacts/presentation/screens/contacts_screen.dart';

/// Root application widget.
class RealEstateCrmApp extends StatelessWidget {
  final ContactRepository contactRepository;
  final FlutterLocalNotificationsPlugin? notifications;

  const RealEstateCrmApp({
    super.key,
    required this.contactRepository,
    this.notifications,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ContactsProvider(
        repository: contactRepository,
        notifications: notifications,
      ),
      child: MaterialApp(
        title: 'Real Estate CRM',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const ContactsScreen(),
      ),
    );
  }
}
