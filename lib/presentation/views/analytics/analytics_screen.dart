import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_utils.dart';
import 'package:intl/intl.dart';
import '../../../data/datasources/analytics_remote_datasource.dart';
import '../../../data/datasources/api_client.dart';
import '../../../data/models/analytics_model.dart';
import '../../../data/repositories/analytics_repository.dart';
import '../../viewmodels/analytics_viewmodel.dart';

class AnalyticsScreen extends StatelessWidget {
  final String userId;
  const AnalyticsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Provider<AnalyticsRepository>(
      create: (_) => AnalyticsRepository(
        remoteDataSource: AnalyticsRemoteDataSource(apiClient: ApiClient()),
      ),
      child: ChangeNotifierProvider(
        create: (context) => AnalyticsViewModel(
          repository: Provider.of<AnalyticsRepository>(context, listen: false),
        )..fetchAll(userId),
        child: _AnalyticsScreenBody(),
      ),
    );
  }
}

class _AnalyticsScreenBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AnalyticsViewModel>(context);
    Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: UiUtils.responsiveAppBar(
        title: 'Your Analytics',
        backgroundColor: AppTheme.surfaceColor,
        centerTitle: true,
      ),
      body: vm.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.errorMessage != null
              ? Center(child: Text(vm.errorMessage!))
              : RefreshIndicator(
                  onRefresh: () => vm.fetchAll(vm.engagement?.createdAt ?? ''),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (kIsWeb)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(
                              'Your Analytics',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        _buildProgressSection(vm.userProgress),
                        const SizedBox(height: 24),
                        _buildStrengthsWeaknessesSection(vm.strengthsWeaknesses),
                        const SizedBox(height: 24),
                        _buildEngagementSection(vm.engagement),
                        const SizedBox(height: 24),
                        _buildRecommendationsSection(vm.recommendations),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildProgressSection(UserProgress? progress) {
    if (progress == null) return const SizedBox.shrink();
    final completed = progress.completedExercises;
    final total = progress.totalExercises;
    final rate = progress.completionRate;
    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart, color: AppTheme.primaryColor),
                SizedBox(width: 10),
                Text('Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: rate,
              minHeight: 10,
              backgroundColor: AppTheme.backgroundColor.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 10),
            Text('$completed / $total exercises completed (${(rate * 100).toStringAsFixed(1)}%)',
                style: const TextStyle(color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildStrengthsWeaknessesSection(StrengthsWeaknesses? sw) {
    if (sw == null) return const SizedBox.shrink();
    final strengths = sw.strengths;
    final weaknesses = sw.weaknesses;
    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700]),
                const SizedBox(width: 10),
                const Text('Strengths & Weaknesses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            if (strengths.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.green),
                  const SizedBox(width: 8),
                  Text('Strengths: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                  Expanded(child: Text(strengths.join(', '), style: const TextStyle(color: AppTheme.textSecondaryColor))),
                ],
              ),
            if (weaknesses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.trending_down, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Weaknesses: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
                    Expanded(child: Text(weaknesses.join(', '), style: const TextStyle(color: AppTheme.textSecondaryColor))),
                  ],
                ),
              ),
            if (strengths.isEmpty && weaknesses.isEmpty)
              const Text('No data available.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEngagementSection(Engagement? engagement) {
    if (engagement == null) return const SizedBox.shrink();
    final logins = engagement.logins;
    final lastActive = engagement.lastActive.isNotEmpty
        ? DateFormat.yMMMd().add_jm().format(DateTime.parse(engagement.lastActive))
        : 'N/A';
    final participation = engagement.participation;
    final createdAt = engagement.createdAt.isNotEmpty
        ? DateFormat.yMMMd().format(DateTime.parse(engagement.createdAt))
        : 'N/A';
    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.insights, color: AppTheme.primaryColor),
                SizedBox(width: 10),
                Text('Engagement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            _buildEngagementStat(Icons.login, 'Logins', logins.toString()),
            _buildEngagementStat(Icons.people, 'Friends', participation.toString()),
            _buildEngagementStat(Icons.access_time, 'Last Active', lastActive),
            _buildEngagementStat(Icons.cake, 'Joined', createdAt),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildEngagementStat(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textSecondaryColor))),
        ],
      ),
    );
  }

  Widget _buildRecommendationsSection(Recommendations? recs) {
    if (recs == null) return const SizedBox.shrink();
    final list = recs.recommendations;
    return Card(
      color: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.recommend, color: Colors.blue[700]),
                const SizedBox(width: 10),
                const Text('Recommendations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor)),
              ],
            ),
            const SizedBox(height: 16),
            ...list.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_right, color: Colors.blueAccent),
                      const SizedBox(width: 6),
                      Expanded(child: Text(rec, style: const TextStyle(color: AppTheme.textSecondaryColor))),
                    ],
                  ),
                )),
            if (list.isEmpty)
              const Text('No recommendations available.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
} 