import 'package:flutter/material.dart';

class CallScreen extends StatelessWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-screen remote video placeholder
          Container(
            color: Colors.black87,
            child: const Center(
              child: Text('Remote Video', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
          ),
          // PiP self-view
          Positioned(
            top: 40,
            right: 20,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[800],
              ),
              child: const Center(
                child: Text('You', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          // Filter selector and controls
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter selector grid
                  SizedBox(
                    height: 80,
                    child: GridView.count(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      shrinkWrap: true,
                      children: List.generate(5, (i) => GestureDetector(
                        onTap: () {},
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            [Icons.face, Icons.emoji_emotions, Icons.face_retouching_natural, Icons.mood, Icons.tag_faces][i],
                            size: 32,
                            color: Colors.deepPurple,
                          ),
                        ),
                      )),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Apply toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Apply to them'),
                        selected: true,
                        onSelected: (_) {},
                      ),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Apply to me'),
                        selected: false,
                        onSelected: (_) {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // End call button
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: FloatingActionButton(
                      backgroundColor: Colors.red,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.call_end, size: 32),
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