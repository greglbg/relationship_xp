import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ResubmitClaimScreen extends StatefulWidget {
  const ResubmitClaimScreen({
    required this.coupleId,
    required this.claimId,
    required this.title,
    required this.xp,
    required this.reviewMessage,
    super.key,
  });

  final String coupleId;
  final String claimId;
  final String title;
  final int xp;
  final String reviewMessage;

  @override
  State<ResubmitClaimScreen> createState() => _ResubmitClaimScreenState();
}

class _ResubmitClaimScreenState extends State<ResubmitClaimScreen> {
  late final TextEditingController titleController;

  bool isSubmitting = false;
  String? validationMessage;

  @override
  void initState() {
    super.initState();

    titleController = TextEditingController(text: widget.title);
  }

  Future<void> resubmitClaim() async {
    final title = titleController.text.trim();

    if (title.isEmpty) {
      setState(() {
        validationMessage = 'Please describe the activity before resubmitting.';
      });

      return;
    }

    setState(() {
      isSubmitting = true;
      validationMessage = null;
    });

    try {
      await FirebaseFirestore.instance
          .collection('couples')
          .doc(widget.coupleId)
          .collection('claims')
          .doc(widget.claimId)
          .update({
            'title': title,
            'xp': widget.xp,
            'status': 'pending',
            'resubmittedAt': FieldValue.serverTimestamp(),

            // These two deletes intentionally clean old photo metadata
            // from claims created before photo support was removed.
            'photoPath': FieldValue.delete(),
            'photoUrl': FieldValue.delete(),

            'reviewMessage': FieldValue.delete(),
            'reviewedByUserId': FieldValue.delete(),
            'reviewedAt': FieldValue.delete(),
          });

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Unable to resubmit this activity.'),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while resubmitting '
            'this activity.',
          ),
        ),
      );
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
      appBar: AppBar(title: const Text('Update Activity')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Partner Feedback',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(widget.reviewMessage),
              ),
              const SizedBox(height: 24),
              Text(
                'Update your activity',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                maxLength: 120,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Activity',
                  hintText: 'Describe what you completed',
                  border: const OutlineInputBorder(),
                  errorText: validationMessage,
                ),
                onChanged: (_) {
                  if (validationMessage != null) {
                    setState(() {
                      validationMessage = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.xp} XP requested',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isSubmitting ? null : resubmitClaim,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(
                  isSubmitting ? 'Resubmitting...' : 'Resubmit for Review',
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Your partner will review the updated '
                'activity again. Requesting changes '
                'does not remove XP or apply a penalty.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
