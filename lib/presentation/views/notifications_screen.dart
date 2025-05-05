import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:skillGenie/presentation/viewmodels/profile_viewmodel.dart';
import '../viewmodels/reclamation_viewmodel.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              // Clear all notifications functionality to be implemented
            },
          ),
        ],
      ),
      body: Consumer<ReclamationViewModel>(
        builder: (context, viewModel, child) {
          final userId =
                  Provider.of<ProfileViewModel>(context, listen: false)
                      .currentProfile
                      ?.id;
          final reclamations = viewModel.reclamations
              .where((r) =>
                  r.user?.id == userId && r.adminResponse != null && !r.isRead)
              .toList();

          if (reclamations.isEmpty) {
            return const Center(
              child: Text('No notifications'),
            );
          }

          return ListView.builder(
            itemCount: reclamations.length,
            itemBuilder: (context, index) {
              final reclamation = reclamations[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.notification_important,
                    color: reclamation.isRead ? Colors.grey : Colors.blue,
                  ),
                  title: Text(
                    reclamation.subject ?? 'Admin Response',
                    style: TextStyle(
                      fontWeight: reclamation.isRead
                          ? FontWeight.normal
                          : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    reclamation.adminResponse ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    reclamation.status,
                    style: TextStyle(
                      color: reclamation.status.toLowerCase() == 'resolved'
                          ? Colors.green
                          : Colors.orange,
                    ),
                  ),
                  onTap: () {
                    if (!reclamation.isRead) {
                      viewModel.markAsRead(reclamation.id!);
                    }
                    context.go('/reclamation');
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
