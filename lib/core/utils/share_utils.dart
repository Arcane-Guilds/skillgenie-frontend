import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../presentation/viewmodels/auth/auth_viewmodel.dart';
import '../constants/api_constants.dart';

/// A utility class for handling various sharing methods
class ShareUtils {
  /// Share content via the native share dialog (uses OS share sheet)
  static Future<void> shareViaSystem(String content) async {
    await Share.share(content);
  }

  /// Share content via WhatsApp
  static Future<void> shareViaWhatsApp(String content) async {
    final encodedContent = Uri.encodeComponent(content);
    final whatsappUrl = 'https://wa.me/?text=$encodedContent';
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    } else {
      throw 'Could not launch WhatsApp';
    }
  }

  /// Share content via Facebook Messenger
  static Future<void> shareViaMessenger(String content) async {
    final encodedContent = Uri.encodeComponent(content);
    final messengerUrl = 'fb-messenger://share/?link=$encodedContent';
    
    if (await canLaunchUrl(Uri.parse(messengerUrl))) {
      await launchUrl(Uri.parse(messengerUrl));
    } else {
      // Fallback to web version if app is not installed
      final webUrl = 'https://www.facebook.com/dialog/send?app_id=YOUR_APP_ID&link=$encodedContent&redirect_uri=YOUR_REDIRECT_URI';
      if (await canLaunchUrl(Uri.parse(webUrl))) {
        await launchUrl(Uri.parse(webUrl));
      } else {
        throw 'Could not launch Messenger';
      }
    }
  }

  /// Copy to clipboard and show snackbar feedback
  static void copyToClipboard(BuildContext context, String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Share party code with selected friends through app
  static Future<void> shareWithFriends(
    BuildContext context, 
    String partyCode, 
    List<String> selectedFriendIds
  ) async {
    try {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      final userId = authViewModel.currentUser?.id;
      final token = authViewModel.token;
      
      if (userId == null) {
        throw Exception('User not logged in');
      }

      if (token == null || token.isEmpty) {
        throw Exception('Authentication token missing');
      }

      // Log for debugging
      print('Sharing party code $partyCode with friends: $selectedFriendIds');
      print('Sender user ID: $userId');
      print('Using auth token: ${token.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/party-code/share-with-friends'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': partyCode,
          'senderUserId': userId,
          'friendIds': selectedFriendIds,
        }),
      );

      // Log API response for debugging
      print('API response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invitation sent to ${selectedFriendIds.length} friends'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (response.statusCode == 401) {
        // Handle unauthorized case
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your session has expired. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to share with friends');
      }
    } catch (e) {
      print('Error sharing with friends: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show share options in a modal bottom sheet
  static Future<void> showShareOptions(
    BuildContext context, 
    String partyCode,
    String challengeTitle,
  ) async {
    final String shareText = 'Join my challenge "$challengeTitle" with code: $partyCode';
    
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share Challenge Code',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  bottomSheetContext, 
                  Icons.share, 
                  'System',
                  () => shareViaSystem(shareText),
                ),
                _buildShareOption(
                  bottomSheetContext, 
                  Icons.copy, 
                  'Copy',
                  () {
                    copyToClipboard(context, shareText);
                    Navigator.pop(bottomSheetContext);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(bottomSheetContext);
                _showFriendSelectionDialog(context, partyCode);
              },
              child: const Text('SHARE WITH FRIENDS'),
            ),
          ],
        ),
      ),
    );
  }

  /// Build a single share option icon button with label
  static Widget _buildShareOption(
    BuildContext context, 
    IconData icon, 
    String label, 
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              child: Icon(icon),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  /// Show dialog to select friends to share with
  static Future<void> _showFriendSelectionDialog(
    BuildContext parentContext,
    String partyCode,
  ) async {
    final List<String> selectedFriendIds = [];
    final authViewModel = Provider.of<AuthViewModel>(parentContext, listen: false);
    final userId = authViewModel.currentUser?.id;
    final token = authViewModel.token;
    
    if (userId == null) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        const SnackBar(
          content: Text('Authentication token is missing'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Store a variable to track if the loading dialog is showing
    bool isLoadingDialogShowing = true;
    
    // Show loading indicator with the parent context
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Print request details for debugging
      print('Requesting friends list');
      print('User ID: $userId');
      print('Auth token: ${token.substring(0, 10)}...');

      // Fetch friends list from API
      final Uri friendsUrl = Uri.parse('${ApiConstants.baseUrl}/friends');
      print('Request URL: $friendsUrl');
      
      final response = await http.get(
        friendsUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      // Close loading indicator using the parent context
      if (isLoadingDialogShowing) {
        Navigator.of(parentContext, rootNavigator: true).pop();
        isLoadingDialogShowing = false;
      }

      // Log API response for debugging
      print('Friends API response: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        List<dynamic> friendsData = [];
        
        // Try to parse the response body
        try {
          if (response.body.isNotEmpty) {
            friendsData = jsonDecode(response.body);
          }
        } catch (e) {
          print('Error parsing friends data: $e');
        }
        
        // Check if friends data is empty
        if (friendsData.isEmpty) {
          // Use the parent context for showing the dialog
          showDialog(
            context: parentContext,
            builder: (context) => AlertDialog(
              title: const Text('No Friends Found'),
              content: const Text('You don\'t have any friends yet. Add some friends first to share challenges with them.'),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          return;
        }

        // Show friends selection dialog using the parent context
        showDialog<void>(
          context: parentContext,
          builder: (dialogContext) {
            return StatefulBuilder(
              builder: (builderContext, setState) {
                return AlertDialog(
                  title: const Text('Select Friends'),
                  content: SizedBox(
                    width: double.maxFinite,
                    height: 300, // Fixed height to ensure visibility
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: friendsData.length,
                      itemBuilder: (context, index) {
                        final friend = friendsData[index];
                        final friendId = friend['_id'];
                        final username = friend['username'] ?? 'Unknown';
                        final email = friend['email'] ?? '';
                        final avatar = friend['avatar'] as String?;
                        
                        final isSelected = selectedFriendIds.contains(friendId);
                        
                        return CheckboxListTile(
                          title: Text(username),
                          subtitle: Text(email),
                          secondary: avatar != null && avatar.isNotEmpty
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(avatar),
                                )
                              : const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                selectedFriendIds.add(friendId);
                              } else {
                                selectedFriendIds.remove(friendId);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('CANCEL'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Close the dialog first
                        Navigator.of(dialogContext).pop();
                        
                        // Check if any friends were selected
                        if (selectedFriendIds.isEmpty) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Please select at least one friend'),
                            ),
                          );
                          return;
                        }
                        
                        // Call the share method with the selected friends
                        shareWithFriends(parentContext, partyCode, selectedFriendIds);
                      },
                      child: const Text('SHARE'),
                    ),
                  ],
                );
              },
            );
          },
        );
      } else if (response.statusCode == 401) {
        // Token expired or invalid - use parent context
        showDialog(
          context: parentContext,
          builder: (context) => AlertDialog(
            title: const Text('Session Expired'),
            content: const Text('Your session has expired. Please log in again.'),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        throw Exception('Failed to load friends: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading friends: $e');
      
      // Make sure to close the loading dialog if it's still showing
      if (isLoadingDialogShowing) {
        Navigator.of(parentContext, rootNavigator: true).pop();
        isLoadingDialogShowing = false;
      }
      
      // Show error dialog with parent context
      showDialog(
        context: parentContext,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Could not load friends: ${e.toString()}'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
} 