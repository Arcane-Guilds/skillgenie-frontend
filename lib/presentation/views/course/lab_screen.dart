import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../data/models/lab_model.dart';
import '../../viewmodels/lab_viewmodel.dart';
import '../../viewmodels/auth/auth_viewmodel.dart';

class LabScreen extends StatefulWidget {
  final String chapterId;

  const LabScreen({
    Key? key,
    required this.chapterId,
  }) : super(key: key);

  @override
  State<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends State<LabScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLab();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadLab() async {
    final labViewModel = Provider.of<LabViewModel>(context, listen: false);
    await labViewModel.fetchLabByChapter(widget.chapterId, context: context);
    
    if (labViewModel.currentLab != null) {
      _codeController.text = labViewModel.currentCode;
      
      // Load hints
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.user != null) {
        await labViewModel.fetchHints(authViewModel.user!.id, context: context);
      }
    }
  }

  void _submitCode() async {
    final labViewModel = Provider.of<LabViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    if (authViewModel.user != null) {
      try {
        labViewModel.updateCode(_codeController.text);
        await labViewModel.submitCode(authViewModel.user!.id, context: context);
        
        // Show results dialog if we have submission data
        if (labViewModel.currentSubmission != null && mounted) {
          await showDialog(
            context: context,
            builder: (context) => _buildResultsDialog(labViewModel.currentSubmission!),
          );
          // Reset submission state after dialog is closed
          labViewModel.resetSubmission();
          labViewModel.clearError();
        } 
        // Show error dialog if we have an error message but no submission
        else if (labViewModel.errorMessage != null && mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Submission Error'),
              content: Text(labViewModel.errorMessage!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          // Clear error state after showing error dialog
          labViewModel.clearError();
        }
      } catch (e) {
        // This should rarely happen now as errors are handled in the ViewModel
        if (mounted) {
          await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Unexpected Error'),
              content: Text('An unexpected error occurred: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
          // Clear error state after showing error dialog
          labViewModel.clearError();
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to submit code')),
      );
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _purchaseHint(int index) async {
    final labViewModel = Provider.of<LabViewModel>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    
    if (authViewModel.user != null) {
      try {
        await labViewModel.purchaseHint(authViewModel.user!.id, index, context: context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hint purchased successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to purchase hint: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to purchase hints')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LabViewModel>(
      builder: (context, labViewModel, child) {
        if (labViewModel.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (labViewModel.errorMessage != null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lab')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${labViewModel.errorMessage}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadLab,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (labViewModel.currentLab == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Lab')),
            body: const Center(child: Text('No lab found for this chapter')),
          );
        }

        final lab = labViewModel.currentLab!;

        if (_isFullScreen) {
          return Scaffold(
            appBar: AppBar(
              title: Text(lab.title),
              actions: [
                IconButton(
                  icon: const Icon(Icons.fullscreen_exit),
                  onPressed: _toggleFullScreen,
                ),
              ],
            ),
            body: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: _buildCodeEditor(labViewModel),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitCode,
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(lab.title),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Instructions'),
                Tab(text: 'Code'),
                Tab(text: 'Resources'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildInstructionsTab(lab),
              _buildCodeTab(labViewModel),
              _buildResourcesTab(lab),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructionsTab(Lab lab) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lab.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            lab.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          const Divider(),
          
          // Introduction
          Text(
            'Introduction',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(lab.content.introduction),
          const SizedBox(height: 16),
          
          // Concept Explanation
          Text(
            'Concept Explanation',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(lab.content.conceptExplanation),
          const SizedBox(height: 16),
          
          // Requirements
          Text(
            'Requirements',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          // Objectives
          Text(
            'Objectives:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...lab.requirements.objectives.map(
            (objective) => Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(objective)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Acceptance Criteria
          Text(
            'Acceptance Criteria:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          ...lab.requirements.acceptanceCriteria.map(
            (criteria) => Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(criteria)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Prerequisites
          if (lab.requirements.prerequisites.isNotEmpty) ...[
            Text(
              'Prerequisites:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            ...lab.requirements.prerequisites.map(
              (prerequisite) => Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(prerequisite)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Difficulty and estimated time
          Row(
            children: [
              Text(
                'Difficulty: ${lab.requirements.difficulty}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
              Text(
                'Estimated time: ${lab.requirements.estimatedTime}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Step by Step Guide
          Text(
            'Step by Step Guide',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          
          ...lab.content.stepByStep.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${index + 1}: ${step.title}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(step.explanation),
                  const SizedBox(height: 8),
                  if (step.codeExample.isNotEmpty) ...[
                    const Text('Example:'),
                    const SizedBox(height: 4),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[200],
                      ),
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: HighlightView(
                        step.codeExample,
                        language: lab.starterCode.language,
                        theme: githubTheme,
                        padding: const EdgeInsets.all(8),
                        textStyle: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (step.tips.isNotEmpty) ...[
                    Text(
                      'Tips:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    ...step.tips.map(
                      (tip) => Padding(
                        padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(tip)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          
          // Hints Section
          Consumer<LabViewModel>(
            builder: (context, labViewModel, child) {
              if (labViewModel.currentHints == null || labViewModel.currentHints!.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Divider(),
                  Text(
                    'Hints',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  ...labViewModel.currentHints!.asMap().entries.map((entry) {
                    final index = entry.key;
                    final hint = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Hint ${index + 1}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                if (!hint.unlocked)
                                  Text(
                                    'Cost: ${hint.coinCost} coins',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            hint.unlocked
                                ? Text(hint.content)
                                : ElevatedButton(
                                    onPressed: () => _purchaseHint(index),
                                    child: const Text('Purchase Hint'),
                                  ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCodeTab(LabViewModel labViewModel) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              const Text('Language: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: labViewModel.selectedLanguage,
                items: labViewModel.currentLab?.supportedLanguages
                    .map(
                      (language) => DropdownMenuItem<String>(
                        value: language,
                        child: Text(language),
                      ),
                    )
                    .toList(),
                onChanged: (language) {
                  if (language != null) {
                    labViewModel.setSelectedLanguage(language);
                  }
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.fullscreen),
                onPressed: _toggleFullScreen,
                tooltip: 'Full Screen',
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _codeController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Code copied to clipboard')),
                  );
                },
                tooltip: 'Copy Code',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _codeController.text = labViewModel.currentLab?.starterCode.code ?? '';
                },
                tooltip: 'Reset Code',
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildCodeEditor(labViewModel),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitCode,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text('Submit'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeEditor(LabViewModel labViewModel) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: TextField(
        controller: _codeController,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Enter your code here...',
        ),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14.0,
        ),
      ),
    );
  }

  Widget _buildResourcesTab(Lab lab) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resources',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          
          // Documentation
          if (lab.resources.documentation.isNotEmpty) ...[
            Text(
              'Documentation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...lab.resources.documentation.map(
              (doc) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse(doc)),
                  child: Text(
                    doc,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // External Links
          if (lab.resources.externalLinks.isNotEmpty) ...[
            Text(
              'External Links',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...lab.resources.externalLinks.map(
              (link) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse(link)),
                  child: Text(
                    link,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Videos
          if (lab.resources.videos.isNotEmpty) ...[
            Text(
              'Video Tutorials',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...lab.resources.videos.map(
              (video) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => launchUrl(Uri.parse(video)),
                  child: Text(
                    video,
                    style: const TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
          
          // Test Cases
          const SizedBox(height: 24),
          const Divider(),
          Text(
            'Test Cases',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...lab.testCases.where((test) => !test.isHidden).map(
            (test) => Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      test.description,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Input: ${test.input}'),
                    const SizedBox(height: 4),
                    Text('Expected Output: ${test.expectedOutput}'),
                  ],
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          const Text('Note: Some test cases are hidden and will only be visible after submission.'),
        ],
      ),
    );
  }

  Widget _buildResultsDialog(LabSubmission submission) {
    final evaluationResult = submission.evaluationResult;
    
    if (evaluationResult == null) {
      return AlertDialog(
        title: const Text('Submission Results'),
        content: const Text('Your submission is being processed. Please try again later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(evaluationResult.passed ? 'Success!' : 'Almost there...'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  evaluationResult.passed ? Icons.check_circle : Icons.info,
                  color: evaluationResult.passed ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  evaluationResult.passed
                      ? 'Your solution passed all tests!'
                      : 'Your solution needs some improvements.',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Score: ${evaluationResult.score}%'),
            const SizedBox(height: 16),
            const Text('Test Results:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...evaluationResult.testResults.map(
              (result) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(
                      result.passed ? Icons.check_circle : Icons.cancel,
                      color: result.passed ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(result.testCase)),
                  ],
                ),
              ),
            ),
            if (evaluationResult.feedback.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Feedback:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...evaluationResult.feedback.map(
                (feedback) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(feedback)),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (evaluationResult.passed) ...[
              const Text('Congratulations! You\'ve completed this lab!'),
              const SizedBox(height: 8),
              Text('You earned ${submission.isComplete ? "0" : Provider.of<LabViewModel>(context, listen: false).currentLab?.rewards.coins.toString() ?? "0"} coins and ${submission.isComplete ? "0" : Provider.of<LabViewModel>(context, listen: false).currentLab?.rewards.xp.toString() ?? "0"} XP!'),
            ] else ...[
              const Text('Keep going! You\'re making progress.'),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
} 