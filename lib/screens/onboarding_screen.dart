import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_button.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;
  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    (emoji: '🐾', title: 'Find Your\nPerfect Companion', body: 'Browse thousands of pets available for adoption or purchase near you.'),
    (emoji: '💬', title: 'Chat With\nOwners Directly', body: 'Message pet owners and shelters instantly to ask questions and arrange meetups.'),
    (emoji: '❤️', title: 'Give a Pet\na Loving Home', body: 'Whether adopting or buying, every match brings a new best friend into your life.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onFinish,
                child: Text('Skip', style: nunito(weight: FontWeight.w700, color: AppColors.muted)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final s = _slides[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryPale,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(s.emoji, style: const TextStyle(fontSize: 64)),
                        ),
                        const SizedBox(height: 48),
                        Text(s.title, textAlign: TextAlign.center, style: nunito(size: 28, weight: FontWeight.w900)),
                        const SizedBox(height: 16),
                        Text(s.body, textAlign: TextAlign.center, style: outfit(size: 16, color: AppColors.muted)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 32 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.warmBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: SizedBox(
                width: double.infinity,
                child: CustomButton(
                  onPressed: () {
                    if (_page == _slides.length - 1) {
                      widget.onFinish();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  text: _page == _slides.length - 1 ? "Let's Get Started" : 'Next',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
