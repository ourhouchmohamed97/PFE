import 'dart:async';
import 'package:bus_tracker/shared/pages/chat.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CallPage extends StatefulWidget {
  final String driverName;

  const CallPage({
    super.key,
    this.driverName = 'Joshua',
  });

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late Timer _timer;
  final Stopwatch _stopwatch = Stopwatch();
  int _seconds = 0;
  String _callStatus = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _startTimer();
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _callStatus = 'In Call';
      });
    });
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _seconds = _stopwatch.elapsed.inSeconds;
      });
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _confirmEndCall() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("End Call?"),
        content: const Text("Are you sure you want to end the call?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit call screen
            },
            child: const Text("End", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
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
            Text(_callStatus, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            Text(
              widget.driverName,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(_formatTime(_seconds),
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 40),
            const CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFFDCEEFF),
              backgroundImage: AssetImage('assets/images/profile.png'),
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
                    onPressed: _confirmEndCall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! < -100) {
                  // Swiped up
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatPage(),
                    ),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  "Swipe up to show chat",
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
