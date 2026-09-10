import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ResubmitClaimScreen extends StatefulWidget {
  const ResubmitClaimScreen({
    required this.coupleId,
    required this.claimId,
    required this.title,
    required this.xp,
    required this.photoPath,
    required this.photoUrl,
    required this.reviewMessage,
    super.key,
  });

  final String coupleId;
  final String claimId;
  final String title;
  final int xp;
  final String photoPath;
  final String photoUrl;
  final String reviewMessage;

  @override
  State<ResubmitClaimScreen> createState() => _ResubmitClaimScreenState();
}

class _ResubmitClaimScreenState extends State<ResubmitClaimScreen> {
  late final TextEditingController titleController;

  final ImagePicker imagePicker = ImagePicker();

  final List<int> xpOptions = [5, 10, 25, 50, 100];

  late int selectedXp;

  XFile? selectedImage;
  bool isLoading = false;
  bool isLoadingExistingPhoto = true;
  String? errorMessage;
  String? existingPhotoUrl;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.title);

    selectedXp = widget.xp;

    loadExistingPhoto();
  }

  bool get hasExistingPhoto {
    return widget.photoPath.trim().isNotEmpty ||
        widget.photoUrl.trim().isNotEmpty;
  }

  Future<void> loadExistingPhoto() async {
    if (!hasExistingPhoto) {
      if (mounted) {
        setState(() {
          existingPhotoUrl = null;
          isLoadingExistingPhoto = false;
        });
      }

      return;
    }

    if (widget.photoPath.trim().isEmpty) {
      if (mounted) {
        setState(() {
          existingPhotoUrl = widget.photoUrl;
          isLoadingExistingPhoto = false;
        });
      }

      return;
    }

    try {
      final storageReference = FirebaseStorage.instance.ref().child(
        widget.photoPath,
      );

      final freshPhotoUrl = await storageReference.getDownloadURL();

      if (mounted) {
        setState(() {
          existingPhotoUrl = freshPhotoUrl;
          isLoadingExistingPhoto = false;
        });
      }
    } on FirebaseException {
      if (mounted) {
        setState(() {
          existingPhotoUrl = widget.photoUrl.trim().isEmpty
              ? null
              : widget.photoUrl;
          isLoadingExistingPhoto = false;
        });
      }
    }
  }

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

  Future<void> resubmitClaim() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        errorMessage = 'Please describe the activity.';
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

    var photoPath = widget.photoPath;
    var photoUrl = existingPhotoUrl ?? widget.photoUrl;

    if (selectedImage != null) {
      try {
        if (photoPath.trim().isEmpty) {
          photoPath =
              'couples/${widget.coupleId}/claims/${widget.claimId}/proof.jpg';
        }

        final storageReference = FirebaseStorage.instance.ref().child(
          photoPath,
        );

        await storageReference.putFile(
          File(selectedImage!.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );

        photoPath = storageReference.fullPath;
        photoUrl = await storageReference.getDownloadURL();
      } on FirebaseException catch (error) {
        if (mounted) {
          setState(() {
            errorMessage =
                'Photo upload failed: ${error.code}. ${error.message ?? ''}';
            isLoading = false;
          });
        }

        return;
      }
    }

    try {
      final updateData = <String, dynamic>{
        'title': title,
        'xp': selectedXp,
        'status': 'pending',
        'resubmittedAt': FieldValue.serverTimestamp(),
        'reviewMessage': FieldValue.delete(),
        'reviewedByUserId': FieldValue.delete(),
        'reviewedAt': FieldValue.delete(),
      };

      if (photoPath.trim().isNotEmpty && photoUrl.trim().isNotEmpty) {
        updateData['photoPath'] = photoPath;
        updateData['photoUrl'] = photoUrl;
      }

      await FirebaseFirestore.instance
          .collection('couples')
          .doc(widget.coupleId)
          .collection('claims')
          .doc(widget.claimId)
          .update(updateData);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          errorMessage =
              'Resubmission failed: ${error.code}. ${error.message ?? ''}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage = 'Something went wrong while resubmitting: $error';
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

  Widget buildProofPhoto() {
    if (selectedImage != null) {
      return Image.file(
        File(selectedImage!.path),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      );
    }

    if (!hasExistingPhoto) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'No photo attached to this activity.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (isLoadingExistingPhoto) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (existingPhotoUrl == null || existingPhotoUrl!.trim().isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(
          child: Text(
            'Unable to display the existing photo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Image.network(
      existingPhotoUrl!,
      height: 220,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return const SizedBox(
          height: 120,
          child: Center(child: Text('Unable to display current proof photo.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Activity')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your partner requested a change',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Partner feedback',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(widget.reviewMessage),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: titleController,
                maxLength: 100,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Activity',
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
              const Text(
                'Photos are optional. You can keep the current photo, '
                'replace it, or add one if there was not one before.',
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: buildProofPhoto(),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isLoading ? null : choosePhotoSource,
                icon: const Icon(Icons.add_a_photo),
                label: Text(
                  selectedImage != null || hasExistingPhoto
                      ? 'Replace Photo'
                      : 'Add Optional Photo',
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Requested XP',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Resubmitting sends this activity back to your partner '
                    'for another review. There is no penalty for needing '
                    'changes.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
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
                onPressed: isLoading ? null : resubmitClaim,
                icon: const Icon(Icons.refresh),
                label: Text(
                  isLoading ? 'Resubmitting...' : 'Update & Resubmit',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
