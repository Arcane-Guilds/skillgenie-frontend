import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillGenie/presentation/viewmodels/profile_viewmodel.dart';
import '../../viewmodels/reclamation_viewmodel.dart';
import '../../../data/models/reclamation_model.dart';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:go_router/go_router.dart';
class ReclamationScreen extends StatefulWidget {
  const ReclamationScreen({super.key});

  @override
  State<ReclamationScreen> createState() => _ReclamationScreenState();
}

class _ReclamationScreenState extends State<ReclamationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReclamationViewModel>().loadReclamations();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {

            // Fallback: Navigate to home or previous screen
            context.go('/settings');
          },
        ),
        title: Consumer<ReclamationViewModel>(
          builder: (context, viewModel, child) {
            final userId = Provider.of<ProfileViewModel>(context, listen: false)
                .currentProfile
                ?.id;
            final unreadCount = viewModel.reclamations
                .where((r) =>
                    r.user?.id == userId &&
                    r.adminResponse != null &&
                    !r.isRead)
                .length;
            return Row(
              children: [
                const Text('Reclamations'),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    child: Text(
                      '${unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
      body: Consumer<ReclamationViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.reclamations.length,
                  itemBuilder: (context, index) {
                    final userId =
                        Provider.of<ProfileViewModel>(context, listen: false)
                            .currentProfile
                            ?.id;
                    final reclamation = viewModel.reclamations
                        .where((r) =>
                            r.user?.id == userId && r.adminResponse != null)
                        .toList()[index];
                    return ReclamationCard(
                      reclamation: reclamation,
                      onTap: () =>
                          _showReclamationDetails(context, reclamation),
                    );
                  },
                ),
              ),
              _buildReclamationForm(viewModel),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReclamationForm(ReclamationViewModel viewModel) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (viewModel.error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        viewModel.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            TextFormField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.subject),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter a message';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: viewModel.isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          await viewModel.submitReclamation(
                            _subjectController.text,
                            _messageController.text,
                          );
                          if (mounted) {
                            if (viewModel.isSuccess) {
                              _subjectController.clear();
                              _messageController.clear();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Reclamation submitted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              viewModel.resetState();
                            } else if (viewModel.error != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(viewModel.error!),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: viewModel.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Submit Reclamation'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReclamationDetails(BuildContext context, Reclamation reclamation) {
    if (!reclamation.isRead) {
      context.read<ReclamationViewModel>().markAsRead(reclamation.id!);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(reclamation.subject ?? 'No Subject'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${reclamation.status}'),
              const SizedBox(height: 8),
              Text('Message: ${reclamation.message}'),
              if (reclamation.adminResponse != null) ...[
                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Admin Response:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(reclamation.adminResponse!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class ReclamationCard extends StatelessWidget {
  final Reclamation reclamation;
  final VoidCallback onTap;

  const ReclamationCard({
    super.key,
    required this.reclamation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text(
          reclamation.subject ?? 'No Subject',
          style: TextStyle(
            fontWeight:
                reclamation.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          reclamation.message ?? 'No message',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildStatusIndicator(context),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    Color statusColor;
    switch (reclamation.status.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!reclamation.isRead)
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue,
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            reclamation.status,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
