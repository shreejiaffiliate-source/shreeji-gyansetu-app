import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/course_model.dart';
import '../../../data/providers/course_provider.dart';
import '../../../data/services/api_service.dart';
import 'pdf_viewer_screen.dart';

class LessonPlayerScreen extends StatefulWidget {
  final LessonModel lesson;
  const LessonPlayerScreen({super.key, required this.lesson});

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  final ApiService _apiService = ApiService();
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.lesson.videoUrl.trim()),
      );
      await _videoPlayerController!.initialize();
      _videoPlayerController!.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitUp],
        placeholder: Container(color: Colors.black),
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primaryCyan,
          handleColor: AppColors.primaryBlue,
        ),
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Could not load video.";
      });
    }
  }

  void _videoListener() {
    if (_videoPlayerController == null || _isCompleted) return;
    final pos = _videoPlayerController!.value.position;
    final dur = _videoPlayerController!.value.duration;

    if (dur != Duration.zero && pos >= (dur - const Duration(milliseconds: 500))) {
      setState(() => _isCompleted = true);
      _handleLessonCompletion();
    }
  }

  void _handleLessonCompletion() async {
    final courseProvider = Provider.of<CourseProvider>(context, listen: false);
    await courseProvider.completeLesson(widget.lesson.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lesson Complete! Progress Synchronized."),
          backgroundColor: AppColors.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showQueryBottomSheet(BuildContext context) {
    final TextEditingController queryController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Crucial: allows the sheet to go full height if needed
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              // Logic: Only apply bottom padding equal to the keyboard height
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                // Optional: Limit height to 80% of screen to keep video visible at top
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                // Use SingleChildScrollView to prevent overflow when keyboard appears
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Lesson Q&A",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              )
                          ),
                          IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: Theme.of(context).iconTheme.color)
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),

                      TextField(
                        controller: queryController,
                        maxLines: 3,
                        style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        decoration: InputDecoration(
                          hintText: "Ask the teacher something...",
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.grey[900] : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          onPressed: isSubmitting ? null : () async {
                            if (queryController.text.trim().isEmpty) return;
                            setModalState(() => isSubmitting = true);
                            bool success = await _apiService.postLessonQuery(
                                widget.lesson.id,
                                queryController.text.trim()
                            );
                            if (success) {
                              queryController.clear();
                              setModalState(() => isSubmitting = false);
                            } else {
                              setModalState(() => isSubmitting = false);
                            }
                          },
                          child: isSubmitting
                              ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Post Question",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),

                      Divider(height: 40, color: Theme.of(context).dividerColor),
                      Text("Your History",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.titleMedium?.color,
                          )
                      ),
                      const SizedBox(height: 10),

                      // History List
                      FutureBuilder<List<dynamic>>(
                        future: _apiService.getLessonQueries(widget.lesson.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(child: Text("No questions yet.",
                                style: TextStyle(color: AppColors.textMuted)));
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            // Disable nested scrolling to let SingleChildScrollView handle it
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final q = snapshot.data![index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.primarySoft.withOpacity(0.1)
                                      : AppColors.primarySoft.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(q['question'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).textTheme.bodyLarge?.color,
                                        )
                                    ),
                                    if (q['answer'] != null) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.black38 : Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          // border: Border.left(color: AppColors.primaryBlue, width: 3),
                                        ),
                                        child: Text(q['answer'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            )
                                        ),
                                      )
                                    ] else ...[
                                      const SizedBox(height: 8),
                                      const Text("Waiting for reply...",
                                          style: TextStyle(fontSize: 12, color: AppColors.primaryCyan, fontStyle: FontStyle.italic)
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _showFeatureSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.primaryBlue,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.title)),
      body: Column(
        children: [
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(widget.lesson.title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.headlineSmall?.color,
                    )
                ),
                const SizedBox(height: 8),
                const Text("Follow along with provided notes.", style: TextStyle(color: AppColors.textMuted)),
                Divider(height: 40, color: Theme.of(context).dividerColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActionIcon(Icons.description, "Notes", onTap: () {
                      if (widget.lesson.notesUrl != null && widget.lesson.notesUrl!.isNotEmpty) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewerScreen(pdfUrl: widget.lesson.notesUrl!, title: "Notes")));
                      } else {
                        _showFeatureSnackBar("No notes available.");
                      }
                    }),
                    _buildActionIcon(
                        Icons.question_answer,
                        "Ask Query",
                        onTap: () => _showQueryBottomSheet(context)
                    ),
                    _buildActionIcon(Icons.download, "Resources", onTap: () => _showFeatureSnackBar("Resources will be available soon.")),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primarySoft.withOpacity(0.3),
              child: Icon(icon, color: AppColors.primaryBlue)
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primaryBlue)),
        ],
      ),
    );
  }
}