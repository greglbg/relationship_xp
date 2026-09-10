import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SubmitClaimScreen extends StatefulWidget {
  const SubmitClaimScreen({required this.coupleId, super.key});

  final String coupleId;

  @override
  State<SubmitClaimScreen> createState() => _SubmitClaimScreenState();
}

class _SubmitClaimScreenState extends State<SubmitClaimScreen> {
  final titleController = TextEditingController();
  final ImagePicker imagePicker = ImagePicker();

  final List<int> xpOptions = [5, 10, 25, 50, 100];

  int selectedXp = 25;
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

    if (selectedImage == null) {
      setState(() {
        errorMessage = 'Please add a photo showing the completed activity.';
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

      final photoPath =
          'couples/${widget.coupleId}/claims/${claimReference.id}/proof.jpg';

      final storageReference = FirebaseStorage.instance.ref().child(photoPath);

      await storageReference.putFile(
        File(selectedImage!.path),
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final photoUrl = await storageReference.getDownloadURL();

      await claimReference.set({
        'title': title,
        'xp': selectedXp,
        'submittedByUserId': user.uid,
        'status': 'pending',
        'photoPath': photoPath,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          if (error.code == 'permission-denied') {
            errorMessage = 'The photo or activity could not be saved because permission was denied.';
          } else {
            errorMessage = error.message ?? 'Unable to submit the activity.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          errorMessage = 'Something went wrong while uploading the photo.';
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
      appBar: AppBar(title: const Text('Submit Activity')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'What did you accomplish?',
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Submit something thoughtful, helpful, or meaningful for your '
                'partner to review.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: titleController,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Activity',
                  hintText: 'Example: Made dinner after a long day',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Photo proof',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'A photo is required so your partner can review the activity.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              if (selectedImage == null)
                OutlinedButton.icon(
                  onPressed: isLoading ? null : choosePhotoSource,
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text('Add Photo'),
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
              ],
              const SizedBox(height: 24),
              Text(
                'Requested XP',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Your partner will review this request before any XP is earned.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: xpOptions.map((xp) {
                  return ChoiceChip(
                    label: Text('$xp XP'),
                    selected: selectedXp == xp,
                    onSelected: isLoading
                        ? null
                        : (_) {
                            setState(() {
                              selectedXp = xp;
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.handshake_outlined),
                      const SizedBox(height: 8),
                      Text(
                        'Activities begin as pending. Your partner should '
                        'review claims in good faith and approve or reject '
                        'them based on whether the activity was completed.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
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
                label: Text(isLoading ? 'Uploading...' : 'Submit for Review'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
