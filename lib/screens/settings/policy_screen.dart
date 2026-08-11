import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../theme/app_theme.dart';

class PolicyScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const PolicyScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends State<PolicyScreen> {
  String? _content;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    try {
      final text = await rootBundle.loadString(widget.assetPath);
      setState(() {
        _content = text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _content = 'Error loading content.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title, style: nunito(size: 18, weight: FontWeight.w800, color: textColor)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Text(
                _content ?? '',
                style: outfit(size: 15, color: isDark ? Colors.white70 : AppColors.darkMid, height: 1.6),
              ),
            ),
    );
  }
}
