import 'dart:async';
import 'package:flutter/material.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Icon(Icons.call, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Your driver", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text("Joshua", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_formatTime(_seconds), style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFFDCEEFF),
              backgroundImage: NetworkImage('https://i.imgur.com/BoN9kdC.png'), // Replace with real driver photo
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  radius: 28,
                  child: const Icon(Icons.videocam_off, color: Colors.black),
                ),
                CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  radius: 28,
                  child: const Icon(Icons.mic_off, color: Colors.black),
                ),
                CircleAvatar(
                  backgroundColor: Colors.red,
                  radius: 28,
                  child: IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Swipe up to show chat", style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
