import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
  final bool openQueries;
  const LessonPlayerScreen({super.key, required this.lesson, this.openQueries = false,});

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

  Timer? _progressSyncTimer;
  double _lastSyncedPosition = -1.0;

  @override
  void initState() {
    super.initState();
    // ✅ STEP 1: Pehle fresh progress fetch karo server se
    _fetchProgressAndInitialize();

    if (widget.openQueries) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showQueryBottomSheet(context);
      });
    }
  }

  // ✅ NEW: Fresh fetching logic before player init
  Future<void> _fetchProgressAndInitialize() async {
    try {
      final double? freshPos = await _apiService.getLatestVideoProgress(widget.lesson.id);
      if (freshPos != null && mounted) {
        setState(() {
          widget.lesson.lastPosition = freshPos;
          _lastSyncedPosition = freshPos; // 👈 Add this line to avoid immediate re-sync
        });
      }
    } catch (e) {
      debugPrint("Resume Fetch Error: $e");
    } finally {
      _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.lesson.videoUrl.trim()),
      );
      await _videoPlayerController!.initialize();

      // ✅ RESUME LOGIC: Ab ye fresh data use karega
      if (widget.lesson.lastPosition > 1) {
        final target = Duration(seconds: widget.lesson.lastPosition.toInt());
        if (target < _videoPlayerController!.value.duration) {
          await _videoPlayerController!.seekTo(target);
        }
      }

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

      _startProgressTimer();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Could not load video.";
        });
      }
    }
  }

  void _showResourcesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 1. Allows the sheet to expand based on content
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Container(
        // 2. Limit height to 60% of screen so it doesn't cover everything
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: SingleChildScrollView( // 3. This FIXES the RenderFlex overflow
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Lesson Resources",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                "Copy and use the following links/info:",
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[900]
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: SelectableLinkify(
                  text: widget.lesson.resources ?? "No resources provided.",
                  onOpen: (link) async {
                    final Uri url = Uri.parse(link.url);
                    if (await canLaunchUrl(url)) {
                      await launchUrl(
                        url,
                        mode: LaunchMode.externalApplication, // Opens in default mobile browser
                      );
                    } else {
                      _showFeatureSnackBar("Could not open link: ${link.url}");
                    }
                  },
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 15,
                  ),
                  linkStyle: const TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _startProgressTimer() {
    _progressSyncTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _syncProgressToBackend();
    });
  }

  void _syncProgressToBackend() {
    if (_videoPlayerController != null && _videoPlayerController!.value.isPlaying) {
      final currentPos = _videoPlayerController!.value.position.inSeconds.toDouble();

      // Sync if moved more than 2 seconds
      if (!_isCompleted && (currentPos - _lastSyncedPosition).abs() >= 2) {
        _apiService.updateVideoProgress(widget.lesson.id, currentPos);
        _lastSyncedPosition = currentPos;
      }
    }
  }

  void _videoListener() {
    if (_videoPlayerController == null || _isCompleted) return;
    final pos = _videoPlayerController!.value.position;
    final dur = _videoPlayerController!.value.duration;

    if (dur != Duration.zero && pos >= (dur - const Duration(milliseconds: 800))) {
      setState(() => _isCompleted = true);
      _handleLessonCompletion();
    }
  }

  void _handleLessonCompletion() async {
    _lastSyncedPosition = 0;
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

  @override
  void dispose() {
    _progressSyncTimer?.cancel();

    // FINAL SYNC on exit
    if (_videoPlayerController != null && !_isCompleted) {
      final finalPos = _videoPlayerController!.value.position.inSeconds.toDouble();
      _apiService.updateVideoProgress(widget.lesson.id, finalPos);
    }

    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  void _showQueryBottomSheet(BuildContext context) async {
    _videoPlayerController?.pause();
    _syncProgressToBackend(); // Force sync immediately on pause

    final TextEditingController queryController = TextEditingController();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
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
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
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
                            setModalState(() => isSubmitting = false);
                            if (success) queryController.clear();
                          },
                          child: isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Post Question", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    _videoPlayerController?.play();
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async { // 👈 Change this line
        if (didPop) return;
        if (_videoPlayerController != null && !_isCompleted) {
          final finalPos = _videoPlayerController!.value.position.inSeconds.toDouble();
          await _apiService.updateVideoProgress(widget.lesson.id, finalPos);
        }
      },
      child: Scaffold(
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
                      _buildActionIcon(Icons.description, "Notes", onTap: () async {
                        if (widget.lesson.notesUrl != null && widget.lesson.notesUrl!.isNotEmpty) {
                          _videoPlayerController?.pause();
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => PdfViewerScreen(
                                      pdfUrl: widget.lesson.notesUrl!,
                                      title: "Notes"
                                  )
                              )
                          );
                          _videoPlayerController?.play();
                        } else {
                          _showFeatureSnackBar("No notes available.");
                        }
                      }),
                      _buildActionIcon(Icons.question_answer, "Ask Query", onTap: () => _showQueryBottomSheet(context)),
                      _buildActionIcon(Icons.download, "Resources", onTap: () {
                        if (widget.lesson.resources != null && widget.lesson.resources!.isNotEmpty) {
                          _showResourcesBottomSheet(context);
                        } else {
                          _showFeatureSnackBar("No resources available.");
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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