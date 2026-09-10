import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/relationship_xp_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const RelationshipXpApp());
}
