import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

class TutorialTooltip extends StatelessWidget {
  final String title;
  final String description;
  final int currentStep;
  final int totalSteps;
  final VoidCallback? onNext;
  final VoidCallback? onPrev;
  final VoidCallback? onSkip;

  const TutorialTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.currentStep,
    required this.totalSteps,
    this.onNext,
    this.onPrev,
    this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Fixed width for the tooltip
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Row (Title + Skip)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C1E4E),
                ),
              ),
              GestureDetector(
                onTap: () {
                  ShowCaseWidget.of(context).dismiss();
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Description
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // 3. Footer (Dots + Navigation)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dots Indicator
              Row(
                children: List.generate(totalSteps, (index) {
                  final isActive = index + 1 == currentStep;
                  return Container(
                    margin: const EdgeInsets.only(right: 6),
                    width: isActive ? 10 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF0C1E4E) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),

              // Buttons
              Row(
                children: [
                  // Back Button (Hide if step 1)
                  if (currentStep > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          ShowCaseWidget.of(context).previous();
                        },
                        child: const Text(
                          "Back",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                  // Next Button
                  ElevatedButton(
                    onPressed: () {
                      if (currentStep == totalSteps) {
                        ShowCaseWidget.of(context).dismiss();
                      } else {
                        ShowCaseWidget.of(context).next();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0C1E4E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(
                      currentStep == totalSteps ? "Finish" : "Next",
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}