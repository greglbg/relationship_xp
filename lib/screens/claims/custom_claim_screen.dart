import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../tasks/task_catalog.dart';

class CustomClaimScreen extends StatefulWidget {
  const CustomClaimScreen({required this.coupleId, super.key});

  final String coupleId;

  @override
  State<CustomClaimScreen> createState() => _CustomClaimScreenState();
}

class _CustomClaimScreenState extends State<CustomClaimScreen> {
  final titleController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();

  bool isLoading = false;
  String? errorMessage;
  XFile? selectedImage;

  Future<void> choosePhotoSource() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Take Photo'),
                  onTap: () {
                    Navigator.of(context).pop();
                    pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.of(context).pop();
                    pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> pickImage(ImageSource source) async {
    try {
      final image = await imagePicker.pickImage(
        source: source,
        imageQuality: 75,
        maxWidth: 1600,
      );

      if (image == null) {
        return;
      }

      if (mounted) {
        setState(() {
          selectedImage = image;
          errorMessage = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage = 'Unable to select that photo.';
        });
      }
    }
  }

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
        errorMessage = 'Please keep the description under 100 characters.';
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

      String? photoPath;
      String? photoUrl;

      if (selectedImage != null) {
        photoPath =
            'couples/${widget.coupleId}/claims/${claimReference.id}/proof.jpg';

        final storageReference = FirebaseStorage.instance.ref().child(
          photoPath,
        );

        await storageReference.putFile(
          File(selectedImage!.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );

        photoUrl = await storageReference.getDownloadURL();
      }

      final claimData = <String, dynamic>{
        'title': title,
        'xp': TaskCatalog.customTaskXp,
        'submittedByUserId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (photoPath != null && photoUrl != null) {
        claimData['photoPath'] = photoPath;
        claimData['photoUrl'] = photoUrl;
      }

      await claimReference.set(claimData);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          if (error.code == 'permission-denied') {
            errorMessage = 'The activity could not be saved because permission was denied.';
          } else {
            errorMessage = error.message ?? 'Unable to submit the activity.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage = 'Something went wrong while submitting the activity.';
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
                'Custom activities are worth ${TaskCatalog.customTaskXp} XP '
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
                  hintText: 'Example: Surprised my partner with breakfast',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Photo',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Optional — add a photo if you would like to share one '
                'with your partner.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (selectedImage == null)
                OutlinedButton.icon(
                  onPressed: isLoading ? null : choosePhotoSource,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Optional Photo'),
                )
              else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    File(selectedImage!.path),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : choosePhotoSource,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Replace Photo'),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: isLoading
                      ? null
                      : () {
                          setState(() {
                            selectedImage = null;
                          });
                        },
                  icon: const Icon(Icons.close),
                  label: const Text('Remove Photo'),
                ),
              ],
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
                        'Custom activity XP is fixed. Your partner must '
                        'approve the activity before the XP is earned.',
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
