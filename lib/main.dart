import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/relationship_xp_app.dart';
import 'firebase_options.dart';

const bool useFirebaseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (useFirebaseEmulators) {
    await connectToFirebaseEmulators();
  }

  runApp(const RelationshipXpApp());
}

Future<void> connectToFirebaseEmulators() async {
  if (kReleaseMode) {
    throw StateError('Firebase emulators must not be used in a release build.');
  }

  const host = '10.0.2.2';

  await FirebaseAuth.instance.useAuthEmulator(host, 9099);

  FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);

  FirebaseFunctions.instance.useFunctionsEmulator(host, 5001);

  await FirebaseStorage.instance.useStorageEmulator(host, 9199);
}
