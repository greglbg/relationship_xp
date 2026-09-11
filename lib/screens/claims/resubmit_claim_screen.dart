import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../tasks/task_catalog.dart';

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

  // Kept temporarily for compatibility with older claims that may still
  // contain a stored download URL.
  final String photoUrl;

  final String reviewMessage;

  @override
  State<ResubmitClaimScreen> createState() => _ResubmitClaimScreenState();
}

class _ResubmitClaimScreenState extends State<ResubmitClaimScreen> {
  late final TextEditingController titleController;

  final ImagePicker imagePicker = ImagePicker();

  XFile? selectedImage;
  bool isLoading = false;
  bool isLoadingExistingPhoto = true;
  String? errorMessage;
  String? existingPhotoUrl;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.title);

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

    // Legacy fallback for old claims that have a URL but no path.
    if (widget.photoPath.trim().isEmpty) {
      if (mounted) {
        setState(() {
          existingPhotoUrl = widget.photoUrl.trim().isEmpty
              ? null
              : widget.photoUrl;

          isLoadingExistingPhoto = false;
        });
      }

      return;
    }

    try {
      final storageReference = FirebaseStorage.instance.ref(widget.photoPath);

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
          // Legacy fallback during our migration away from
          // stored download URLs.
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

    var photoPath = widget.photoPath;

    if (selectedImage != null) {
      try {
        photoPath =
            'temporaryPhotos/couples/'
            '${widget.coupleId}/claims/'
            '${widget.claimId}/proof.jpg';

        final storageReference = FirebaseStorage.instance.ref(photoPath);

        await storageReference.putFile(
          File(selectedImage!.path),
          SettableMetadata(contentType: 'image/jpeg'),
        );

        photoPath = storageReference.fullPath;
      } on FirebaseException catch (error) {
        if (mounted) {
          setState(() {
            errorMessage =
                'Photo upload failed: '
                '${error.code}. '
                '${error.message ?? ''}';

            isLoading = false;
          });
        }

        return;
      }
    }

    try {
      final updateData = <String, dynamic>{
        'title': title,
        'xp': TaskCatalog.customTaskXp,
        'status': 'pending',
        'resubmittedAt': FieldValue.serverTimestamp(),
        'reviewMessage': FieldValue.delete(),
        'reviewedByUserId': FieldValue.delete(),
        'reviewedAt': FieldValue.delete(),
      };

      if (photoPath.trim().isNotEmpty) {
        updateData['photoPath'] = photoPath;
      }

      // If this claim used the old data model, remove the stored URL
      // when it is resubmitted with a usable Storage path.
      if (photoPath.trim().isNotEmpty && widget.photoUrl.trim().isNotEmpty) {
        updateData['photoUrl'] = FieldValue.delete();
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
              'Resubmission failed: '
              '${error.code}. '
              '${error.message ?? ''}';
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          errorMessage =
              'Something went wrong while '
              'resubmitting: $error';
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
            'Photo is no longer available.',
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
          child: Center(
            child: Text(
              'Photo is no longer available.',
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  Widget buildTemporaryPhotoNotice(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Temporary Photos',
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Photos are optional and are '
                    'normally removed from '
                    'Relationship XP approximately '
                    '3 days after upload.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Do not upload sensitive, '
                    'intimate, confidential, or '
                    'other content you would not '
                    'want stored on the service.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Photos may be accessible to '
                    'authorized administrators when '
                    'reasonably necessary to operate, '
                    'maintain, secure, or troubleshoot '
                    'the service.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                'Photos are optional. You can keep '
                'the current photo, replace it, or '
                'add one if there was not one before.',
              ),
              const SizedBox(height: 12),
              buildTemporaryPhotoNotice(context),
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
                        'Custom activity XP is fixed '
                        'and cannot be changed.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Resubmitting sends this activity '
                    'back to your partner for another '
                    'review. There is no penalty for '
                    'needing changes.',
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
