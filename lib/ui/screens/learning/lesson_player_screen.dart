import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class LessonPlayerScreen extends StatefulWidget {
  final LessonModel lesson;

  const LessonPlayerScreen({super.key, required this.lesson});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    debugPrint("--- ATTEMPTING TO PLAY: ${widget.lesson.videoUrl} ---");
    try {
      // 1. Initialize VideoPlayer with your Django Media URL
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.lesson.videoUrl.trim()),
      );

      await _videoPlayerController!.initialize();

      // 2. Wrap with Chewie for professional controls
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        // Allows the video to go full-screen properly
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        placeholder: Container(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryCyan,
          handleColor: AppColors.primaryBlue,
          bufferedColor: Colors.grey,
          backgroundColor: Colors.white24,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not load video. Please check your connection.";
      });
      debugPrint("Video Player Error: $e");
    }
  }

  @override
  void dispose() {
    // 3. Proper clean up of controllers
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        // backgroundColor: AppColors.primaryBlue,
        // leading: const BackButton(
        //   color: Colors.white, // Change your color here
        // ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video Section
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.white)))
                  : Chewie(controller: _chewieController!),
            ),
          ),

          // Details Section
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lesson.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "In this lesson, we will cover the core concepts as outlined in the curriculum. Please follow along with the provided notes.",
                        style: TextStyle(color: AppColors.textMuted, height: 1.5, fontSize: 14),
                      ),
                      const Divider(height: 40),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildActionIcon(Icons.description, "Notes"),
                          _buildActionIcon(Icons.question_answer, "Ask Query"),
                          _buildActionIcon(Icons.download, "Resources"),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.primarySoft,
          child: Icon(icon, color: AppColors.primaryBlue),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue, fontWeight: FontWeight.w500)),
      ],
    );
  }
}