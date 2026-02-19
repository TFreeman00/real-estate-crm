import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app.dart';
import 'features/contacts/data/repositories/contact_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final contactRepository = ContactRepository();
  final notifications = FlutterLocalNotificationsPlugin();

  runApp(
    RealEstateCrmApp(
      contactRepository: contactRepository,
      notifications: notifications,
    ),
  );
}
