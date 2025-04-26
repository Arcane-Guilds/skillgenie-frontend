import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import '../../core/theme/app_theme.dart';
import '../../services/ai_service.dart';

// App-wide primary color - changing from purple to blue
const Color kPrimaryBlue = Color(0xFF29B6F6); // Matching the blue in the app

class GenieAvatar extends StatefulWidget {
  final AvatarState state;
  final String? message;
  final VoidCallback? onMessageComplete;
  final VoidCallback? onTap;
  final double size;

  const GenieAvatar({
    Key? key,
    this.state = AvatarState.idle,
    this.message,
    this.onMessageComplete,
    this.onTap,
    this.size = 150,
  }) : super(key: key);

  @override
  State<GenieAvatar> createState() => _GenieAvatarState();
}

class _GenieAvatarState extends State<GenieAvatar> with TickerProviderStateMixin {
  late AnimationController _floatController;
  late AnimationController _bouncyController;
  bool _isAnimatingMessage = false;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    _bouncyController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    
    // Start the floating animation and loop it
    _floatController.repeat(reverse: true);
    
    // If we have a message, set the flag
    if (widget.message != null) {
      _isAnimatingMessage = true;
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _bouncyController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(GenieAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.message != null && oldWidget.message != widget.message) {
      setState(() {
        _isAnimatingMessage = true;
      });
      _bouncyController.reset();
      _bouncyController.forward();
    }
  }

  String _getAvatarAsset() {
    switch (widget.state) {
      case AvatarState.thinking:
        return 'thinking_genie';
      case AvatarState.celebrating:
        return 'celebrating_genie';
      case AvatarState.explaining:
        return 'explaining_genie';
      case AvatarState.idle:
      default:
        return 'idle_genie';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.message != null && _isAnimatingMessage)
            _buildSpeechBubble(context),
          const SizedBox(height: 10),
          _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, sin(_floatController.value * 2 * pi) * 5),
          child: child,
        );
      },
      child: Container(
        height: widget.size,
        width: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              kPrimaryBlue.withOpacity(0.3), // Changed to blue
              Colors.transparent,
            ],
            radius: 0.8,
          ),
        ),
        child: _buildGenieCharacter(),
      ).animate(onPlay: (controller) => controller.repeat())
       .shimmer(duration: 2.seconds, color: kPrimaryBlue.withOpacity(0.3)), // Changed to blue
    );
  }

  Widget _buildGenieCharacter() {
    // This is a placeholder for the actual character design
    // In a real implementation, this would use actual character assets
    return Stack(
      alignment: Alignment.center,
      children: [
        // Genie body
        Container(
          height: widget.size * 0.7,
          width: widget.size * 0.7,
          decoration: BoxDecoration(
            color: kPrimaryBlue, // Changed to blue
            shape: BoxShape.circle,
          ),
        ),
        
        // Genie face
        Positioned(
          top: widget.size * 0.25,
          child: Container(
            height: widget.size * 0.3,
            width: widget.size * 0.4,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(widget.size * 0.15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Left eye
                Container(
                  height: widget.size * 0.1,
                  width: widget.size * 0.1,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                ),
                // Right eye
                Container(
                  height: widget.size * 0.1,
                  width: widget.size * 0.1,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Genie smile
        Positioned(
          bottom: widget.size * 0.15,
          child: Container(
            height: widget.size * 0.1,
            width: widget.size * 0.3,
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(widget.size * 0.05),
            ),
            child: Center(
              child: Container(
                height: widget.size * 0.05,
                width: widget.size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(widget.size * 0.025),
                ),
              ),
            ),
          ),
        ),
        
        // Glowing effect for the genie
        if (widget.state == AvatarState.celebrating)
          Container(
            height: widget.size,
            width: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kPrimaryBlue.withOpacity(0.7), // Changed to blue
                  Colors.transparent,
                ],
                radius: 0.5,
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat())
           .fadeIn(duration: 1.seconds).fadeOut(duration: 1.seconds),
      ],
    ).animate()
     .scale(duration: 300.ms, curve: Curves.easeInOut, begin: const Offset(1.0, 1.0), end: const Offset(1.1, 1.1))
     .then()
     .scale(duration: 300.ms, curve: Curves.easeInOut, begin: const Offset(1.1, 1.1), end: const Offset(1.0, 1.0))
     .then()
     .custom(
       duration: 600.ms,
       builder: (context, value, child) => Transform.rotate(
         angle: cos(value * pi * 2) * 0.05,
         child: child,
       ),
     );
  }

  Widget _buildSpeechBubble(BuildContext context) {
    return Animate(
      effects: [
        ScaleEffect(
          duration: 300.ms,
          curve: Curves.easeOutBack,
        ),
        ShimmerEffect(
          duration: 1.seconds,
          delay: 300.ms,
          color: kPrimaryBlue.withOpacity(0.3), // Changed to blue
        ),
      ],
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          minWidth: 150,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: kPrimaryBlue.withOpacity(0.2), // Changed to blue
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: kPrimaryBlue.withOpacity(0.5), // Changed to blue
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  widget.message ?? '',
                  textStyle: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  speed: const Duration(milliseconds: 40),
                ),
              ],
              totalRepeatCount: 1,
              displayFullTextOnTap: true,
              stopPauseOnTap: true,
              onFinished: () {
                setState(() {
                  _isAnimatingMessage = false;
                });
                if (widget.onMessageComplete != null) {
                  widget.onMessageComplete!();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum AvatarState {
  idle,
  thinking,
  explaining,
  celebrating,
}

class AvatarWithMessage extends StatelessWidget {
  final String message;
  final AvatarState state;
  final VoidCallback? onDismiss;
  
  const AvatarWithMessage({
    Key? key,
    required this.message,
    this.state = AvatarState.explaining,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GenieAvatar(
            state: state,
            size: 80,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
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
                    color: kPrimaryBlue.withOpacity(0.1), // Changed to blue
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Genie',
                    style: Theme.of(context).textTheme.labelMedium!.copyWith(
                      color: kPrimaryBlue, // Changed to blue
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AskGenieWidget extends StatefulWidget {
  final String learningStyle;
  final String selectedSkill;
  final String skillLevel;
  
  const AskGenieWidget({
    Key? key,
    required this.learningStyle,
    required this.selectedSkill,
    required this.skillLevel,
  }) : super(key: key);

  @override
  State<AskGenieWidget> createState() => _AskGenieWidgetState();
}

class _AskGenieWidgetState extends State<AskGenieWidget> {
  final TextEditingController _questionController = TextEditingController();
  String? _response;
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _isLoading = true;
      _response = null;
    });

    try {
      final response = await AIService.getGenieResponse(
        userQuestion: question,
        learningStyle: widget.learningStyle,
        selectedSkill: widget.selectedSkill,
        skillLevel: widget.skillLevel,
      );

      setState(() {
        _response = response;
        _isLoading = false;
      });

      // Clear the text field
      _questionController.clear();
    } catch (e) {
      setState(() {
        _response = 'Sorry, I had trouble understanding that. Could you try asking in a different way?';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Response from Genie (if any)
          if (_response != null) 
            AvatarWithMessage(message: _response!),

          const SizedBox(height: 10),
          
          // Question input field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'Ask Genie a question...',
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _askQuestion(),
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kPrimaryBlue, // Changed to blue
                ),
                child: IconButton(
                  icon: _isLoading 
                    ? SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                      ),
                  onPressed: _isLoading ? null : _askQuestion,
                ),
              ).animate()
              .scaleXY(end: 1.05, duration: 300.ms)
              .then(delay: 100.ms)
              .scaleXY(end: 1.0, duration: 300.ms),
            ],
          ),
        ],
      ),
    );
  }
} 