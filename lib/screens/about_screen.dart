import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import 'basic_credits_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final theme = settings.currentTheme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Model Statistics",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: colorScheme.surface,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(textTheme, "Final Evaluation", colorScheme),
            const SizedBox(height: 15),
            LayoutBuilder(
              builder: (context, constraints) {
                final double spacing = 12.0;
                final double cardWidth = (constraints.maxWidth - spacing) / 2;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    SizedBox(width: cardWidth, child: _buildStatCard(context, "F1-Score", "0.9661", Icons.balance, colorScheme.primary, colorScheme)),
                    SizedBox(width: cardWidth, child: _buildStatCard(context, "mAP@50", "0.9037", Icons.bar_chart, colorScheme.primary, colorScheme)),
                    SizedBox(width: cardWidth, child: _buildStatCard(context, "Precision", "0.8431", Icons.gps_fixed, colorScheme.primary, colorScheme)),
                    SizedBox(width: cardWidth, child: _buildStatCard(context, "Recall", "0.9091", Icons.visibility, colorScheme.primary, colorScheme)),
                  ],
                );
              },
            ),
            const SizedBox(height: 30),
            _buildSectionTitle(textTheme, "Class Performance", colorScheme),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildClassRow(textTheme, "PODBORER", "0.986", "0.848", colorScheme),
                  const Divider(height: 25),
                  _buildClassRow(textTheme, "BLACKPOD", "0.888", "0.691", colorScheme),
                  const Divider(height: 25),
                  _buildClassRow(textTheme, "HEALTHY", "0.883", "0.715", colorScheme),
                  const Divider(height: 25),
                  _buildClassRow(textTheme, "MIRID", "0.857", "0.679", colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Confusion Matrix Analysis",
              style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            const SizedBox(height: 10),
            _buildStaticImage(context, "assets/images/confusion_matrix.png", colorScheme),
            const SizedBox(height: 5),
            const SizedBox(height: 30),
            _buildSectionTitle(textTheme, "Dataset Distribution", colorScheme),
            const SizedBox(height: 10),
            Text(
              "Instance Count Per Class",
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            _buildDatasetBar(context, "HEALTHY", "3,588", 1.0, colorScheme.primary, colorScheme),
            const SizedBox(height: 10),
            _buildDatasetBar(context, "PODBORER", "3,389", 0.94, colorScheme.secondary, colorScheme),
            const SizedBox(height: 10),
            _buildDatasetBar(context, "MIRID", "2,996", 0.83, colorScheme.tertiary, colorScheme),
            const SizedBox(height: 10),
            _buildDatasetBar(context, "BLACKPOD", "2,884", 0.80, colorScheme.error, colorScheme),
            const SizedBox(height: 30),
            _buildSectionTitle(textTheme, "Performance Curves", colorScheme),
            const SizedBox(height: 15),
            SizedBox(
              height: 200,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildGraphCard(context, "assets/images/BoxF1_curve.png", "F1 Confidence", colorScheme),
                  const SizedBox(width: 15),
                  _buildGraphCard(context, "assets/images/BoxPR_curve.png", "Precision-Recall", colorScheme),
                  const SizedBox(width: 15),
                  _buildGraphCard(context, "assets/images/training_graphs.png", "Training Losses", colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle(textTheme, "Inference Details", colorScheme),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2), width: 2),
              ),
              child: Column(
                children: [
                  _buildDetailRow(textTheme, "Pre-process", "1.0ms", colorScheme),
                  const SizedBox(height: 10),
                  _buildDetailRow(textTheme, "Inference", "4.7ms", colorScheme),
                  const SizedBox(height: 10),
                  _buildDetailRow(textTheme, "Post-process", "0.5ms", colorScheme),
                  const SizedBox(height: 10),
                  _buildDetailRow(textTheme, "Total Images", "582", colorScheme),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BasicCreditsScreen()),
                ),
                icon: Icon(Icons.people_alt_rounded, color: colorScheme.primary, size: 20),
                label: Text(
                  'Credits',
                  style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showZoomableImage(BuildContext context, String assetPath) {
    showDialog(
      context: context,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Container(
          color: Colors.black.withValues(alpha: 0.9),
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.asset(assetPath),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(TextTheme textTheme, String title, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildStaticImage(BuildContext context, String assetPath, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _showZoomableImage(context, assetPath),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Image.asset(
                assetPath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: colorScheme.surfaceContainerHighest,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, color: colorScheme.error),
                          const SizedBox(height: 8),
                          Text("Missing: $assetPath", style: TextStyle(color: colorScheme.onSurface)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGraphCard(BuildContext context, String assetPath, String title, ColorScheme colorScheme) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showZoomableImage(context, assetPath),
          child: Container(
            height: 160,
            width: 200,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      assetPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: colorScheme.error),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(title, style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color iconColor, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.05)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 16),
          Text(value, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
          Text(label, style: textTheme.labelMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildClassRow(TextTheme textTheme, String className, String score1, String score2, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(flex: 3, child: Text(className, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold))),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score1, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              Text("mAP@50", style: textTheme.labelSmall?.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score2, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
              Text("mAP@95", style: textTheme.labelSmall?.copyWith(fontSize: 10, color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDatasetBar(BuildContext context, String label, String count, double percentage, Color color, ColorScheme colorScheme) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            Text(count, style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10))),
            FractionallySizedBox(
              widthFactor: percentage,
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(TextTheme textTheme, String label, String value, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        Text(value, style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontFamily: 'Courier')),
      ],
    );
  }
}