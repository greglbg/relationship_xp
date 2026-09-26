import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../tasks/task_catalog.dart';

class CustomClaimScreen extends StatefulWidget {
  const CustomClaimScreen({required this.coupleId, super.key});

  final String coupleId;

  @override
  State<CustomClaimScreen> createState() => _CustomClaimScreenState();
}

class _CustomClaimScreenState extends State<CustomClaimScreen> {
  final titleController = TextEditingController();

  bool isLoading = false;
  String? errorMessage;

  Future<void> submitClaim() async {
    final user = FirebaseAuth.instance.currentUser;
    final title = titleController.text.trim();

    if (user == null) {
      setState(() {
        errorMessage = 'No signed-in user was found.';
      });

      return;
    }

    if (title.isEmpty) {
      setState(() {
        errorMessage = 'Please describe what you completed.';
      });

      return;
    }

    if (title.length > 100) {
      setState(() {
        errorMessage =
            'Please keep the description '
            'under 100 characters.';
      });

      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final claimReference = FirebaseFirestore.instance
          .collection('couples')
          .doc(widget.coupleId)
          .collection('claims')
          .doc();

      final claimData = <String, dynamic>{
        'title': title,
        'xp': TaskCatalog.customTaskXp,
        'submittedByUserId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await claimReference.set(claimData);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          if (error.code == 'permission-denied') {
            errorMessage =
                'The activity could not be saved '
                'because permission was denied.';
          } else {
            errorMessage = error.message ?? 'Unable to submit the activity.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage =
              'Something went wrong while '
              'submitting the activity.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Custom Activity')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a custom activity',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Custom activities are worth '
                '${TaskCatalog.customTaskXp} XP '
                'and require your partner\'s approval.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: titleController,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Activity',
                  hintText:
                      'Example: Surprised my partner '
                      'with breakfast',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.stars_outlined),
                      const SizedBox(height: 8),
                      Text(
                        '${TaskCatalog.customTaskXp} XP',
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Custom activity XP is fixed. '
                        'Your partner must approve '
                        'the activity before the XP '
                        'is earned.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (errorMessage != null) ...[
                Text(
                  errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton.icon(
                onPressed: isLoading ? null : submitClaim,
                icon: const Icon(Icons.send),
                label: Text(
                  isLoading ? 'Submitting...' : 'Submit for Partner Review',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
