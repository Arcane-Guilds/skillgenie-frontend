import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:skillGenie/core/services/service_locator.dart';
import 'package:skillGenie/presentation/viewmodels/chatbot_viewmodel.dart';
import 'package:skillGenie/presentation/widgets/avatar_widget.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _promptController = TextEditingController();
  AvatarState _avatarState = AvatarState.idle;
  final Connectivity _connectivity = Connectivity();
  bool _isConnected = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _setupConnectivityListener();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });
  }

  void _setupConnectivityListener() {
    _connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => serviceLocator<ChatbotViewModel>(),
      child: Consumer<ChatbotViewModel>(
        builder: (context, viewModel, child) {
          // Update avatar state based on loading state
          if (viewModel.isLoading) {
            _avatarState = AvatarState.thinking;
          } else if (viewModel.chatHistory.isNotEmpty && 
                    !viewModel.chatHistory.last.isPrompt) {
            _avatarState = AvatarState.explaining;
          } else if (!_isConnected) {
            _avatarState = AvatarState.idle;
          } else {
            _avatarState = AvatarState.idle;
          }
          
          // Scroll to bottom when a new message is added
          if (viewModel.chatHistory.isNotEmpty) {
            _scrollToBottom();
          }
          
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              title: const Text("SkillGenie Assistant", 
                style: TextStyle(fontWeight: FontWeight.bold)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: viewModel.clearChatHistory,
                ),
              ],
            ),
            body: Column(
              children: [
                if (viewModel.isLoading)
                  LinearProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  ),
                  
                if (!_isConnected)
                  _buildNetworkErrorBanner(context),
                  
                if (viewModel.errorMessage != null)
                  _buildErrorBanner(context, viewModel.errorMessage!),
                
                // Avatar section at the top
                  Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: GenieAvatar(
                    state: _avatarState,
                    message: viewModel.isLoading 
                        ? "Thinking..." 
                        : !_isConnected 
                            ? "I'm having trouble connecting to the internet..."
                            : null,
                    size: 120,
                  ),
                ).animate().fadeIn(duration: 500.ms),
                  
                Expanded(
                  child: viewModel.chatHistory.isEmpty && !viewModel.isLoading
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: viewModel.chatHistory.length,
                    itemBuilder: (context, index) {
                      final message = viewModel.chatHistory[index];
                            final isLastAiResponse = !message.isPrompt && 
                                                   index == viewModel.chatHistory.length - 1 && 
                                                   viewModel.showTypingAnimation;
                            
                      return _buildChatMessage(
                              context,
                        isPrompt: message.isPrompt,
                        message: message.message,
                        date: DateFormat('hh:mm a').format(message.time),
                        imagePath: message.imagePath,
                              animateText: isLastAiResponse,
                              onAnimationComplete: () {
                                if (isLastAiResponse) {
                                  viewModel.setTypingAnimationComplete();
                                }
                              },
                      );
                    },
                  ),
                ),
                
                _buildInputBar(context, viewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNetworkErrorBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.orange.shade100,
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No internet connection. Some features may be limited.',
              style: TextStyle(color: Colors.orange.shade900),
            ),
          ),
        ],
      ),
    ).animate().slide(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
      duration: 300.ms,
    );
  }

  Widget _buildErrorBanner(BuildContext context, String errorMessage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color: Colors.red.shade100,
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Start a conversation with SkillGenie',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ask questions about your learning journey, get practice exercises, or discuss any topic you want to learn about.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context, ChatbotViewModel viewModel) {
    final bool isDisabled = viewModel.isLoading || !_isConnected;
    
    return Container(
                  padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
                  child: Row(
                    children: [
                      // Button to pick an image from the gallery
                      IconButton(
            icon: Icon(
              Icons.photo,
              color: isDisabled 
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            onPressed: isDisabled ? null : viewModel.pickAndSendImage,
          ).animate().scale(
            duration: 200.ms,
            curve: Curves.easeOut,
            begin: const Offset(1, 1),
            end: const Offset(1.1, 1.1),
          ),
          
                      Expanded(
                        flex: 20,
                        child: TextField(
                          controller: _promptController,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
                          decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDisabled
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                hintText: isDisabled
                    ? _isConnected ? "Please wait..." : "Waiting for connection..."
                    : "Ask SkillGenie...",
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              enabled: !isDisabled,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: isDisabled ? null : (text) {
                if (text.trim().isNotEmpty) {
                  viewModel.sendTextMessage(text.trim());
                  _promptController.clear();
                }
              },
            ),
          ),
          
                      const SizedBox(width: 10),
          
                      GestureDetector(
            onTap: isDisabled ? null : () {
                                final message = _promptController.text.trim();
                                if (message.isNotEmpty) {
                                  viewModel.sendTextMessage(message);
                                  _promptController.clear();
                                }
                              },
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: isDisabled
                    ? [Colors.grey.shade300, Colors.grey.shade400]
                    : [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: isDisabled 
                    ? [] 
                    : [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                      ),
                    ],
                  ),
              child: Icon(
                Icons.send,
                color: isDisabled ? Colors.grey.shade500 : Colors.white,
                size: 22,
              ),
            ),
          ).animate()
            .scaleXY(end: 1.05, duration: 300.ms)
            .then(delay: 100.ms)
            .scaleXY(end: 1.0, duration: 300.ms),
        ],
      ),
    );
  }

  /// Widget for displaying chat messages
  Widget _buildChatMessage(
    BuildContext context, {
    required bool isPrompt,
    required String message,
    required String date,
    String? imagePath,
    bool animateText = false,
    VoidCallback? onAnimationComplete,
  }) {
    return Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isPrompt ? 40 : 16,
        right: isPrompt ? 16 : 40,
      ),
      child: Column(
        crossAxisAlignment: isPrompt ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isPrompt && !animateText)
            // For regular assistant messages
            AvatarWithMessage(
              message: message,
              state: AvatarState.explaining,
            )
          else if (!isPrompt && animateText)
            // For animated typing assistant messages
            _buildAnimatedAssistantMessage(context, message, onAnimationComplete)
          else
            // For user messages
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPrompt 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isPrompt ? const Radius.circular(0) : null,
                  bottomLeft: !isPrompt ? const Radius.circular(0) : null,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(imagePath),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
                        ),
              ),
            ),
          Text(
            message,
            style: TextStyle(
                      fontSize: 16,
                      color: isPrompt 
                        ? Colors.white 
                        : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
            child: Text(
              date,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slide(begin: const Offset(0, 0.1), end: const Offset(0, 0));
  }
  
  /// Builds an animated typing effect for the assistant messages
  Widget _buildAnimatedAssistantMessage(
    BuildContext context, 
    String message,
    VoidCallback? onAnimationComplete,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0, top: 4.0),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.assistant,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(
                  'SkillGenie',
            style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
              fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedTextKit(
                  animatedTexts: [
                    TypewriterAnimatedText(
                      message,
                      textStyle: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      speed: const Duration(milliseconds: 20),
                      cursor: '▌',
                    ),
                  ],
                  displayFullTextOnTap: true,
                  isRepeatingAnimation: false,
                  totalRepeatCount: 1,
                  onFinished: onAnimationComplete,
                ),
                // Typing indicator that shows until animation starts
                if (message.isEmpty)
                  _buildTypingIndicator(context),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  /// Typing indicator dots animation
  Widget _buildTypingIndicator(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDot(context, 0),
        _buildDot(context, 150),
        _buildDot(context, 300),
      ],
    );
  }

  Widget _buildDot(BuildContext context, int delay) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
        borderRadius: BorderRadius.circular(4),
      ),
    ).animate(
      onPlay: (controller) => controller.repeat(reverse: true),
    ).scaleXY(
      begin: 0.6,
      end: 1.2,
      duration: const Duration(milliseconds: 600),
      delay: Duration(milliseconds: delay),
      curve: Curves.easeInOut,
    );
  }
} 