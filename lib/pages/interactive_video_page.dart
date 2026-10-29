import 'package:flutter/material.dart';
import '../widgets/navigation_wrapper.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);
const Color lightRed = Color(0xFFFFE5E5);

class InteractiveVideoPage extends StatefulWidget {
  const InteractiveVideoPage({super.key});

  @override
  State<InteractiveVideoPage> createState() => _InteractiveVideoPageState();
}

class _InteractiveVideoPageState extends State<InteractiveVideoPage> {
  final List<VideoLesson> videoLessons = [
    VideoLesson(
      id: 1,
      title: "Bonjour",
      description: "Apprenez à dire bonjour en langue des signes",
      thumbnailUrl: "assets/images/bonjour_thumb.png",
      videoUrl: "assets/videos/bonjour.mp4",
      duration: "00:30",
      difficulty: "Débutant",
    ),
    VideoLesson(
      id: 2,
      title: "Merci",
      description: "Comment exprimer la gratitude",
      thumbnailUrl: "assets/images/merci_thumb.png",
      videoUrl: "assets/videos/merci.mp4",
      duration: "00:25",
      difficulty: "Débutant",
    ),
    VideoLesson(
      id: 3,
      title: "Au revoir",
      description: "Dire au revoir poliment",
      thumbnailUrl: "assets/images/aurevoir_thumb.png",
      videoUrl: "assets/videos/aurevoir.mp4",
      duration: "00:35",
      difficulty: "Débutant",
    ),
    VideoLesson(
      id: 4,
      title: "Comment allez-vous?",
      description: "Demander comment quelqu'un va",
      thumbnailUrl: "assets/images/comment_thumb.png",
      videoUrl: "assets/videos/comment.mp4",
      duration: "00:45",
      difficulty: "Intermédiaire",
    ),
    VideoLesson(
      id: 5,
      title: "Je t'aime",
      description: "Exprimer l'amour en langue des signes",
      thumbnailUrl: "assets/images/jtaime_thumb.png",
      videoUrl: "assets/videos/jtaime.mp4",
      duration: "00:40",
      difficulty: "Intermédiaire",
    ),
  ];

  String selectedCategory = "Tous";

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      selectedIndex: 2, // Games index
      child: Scaffold(
        backgroundColor: bgGrey,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryRed),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: const Text(
            "Vidéo Interactive",
            style: TextStyle(
              color: primaryRed,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        body: Column(
          children: [
            // Category Filter
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ["Tous", "Débutant", "Intermédiaire", "Avancé"].map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: selectedCategory == category,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                              backgroundColor: Colors.grey.shade200,
                              selectedColor: primaryRed.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: selectedCategory == category ? primaryRed : Colors.black,
                                fontWeight: selectedCategory == category ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Video Lessons List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: videoLessons.length,
                itemBuilder: (context, index) {
                  final lesson = videoLessons[index];
                  if (selectedCategory != "Tous" && lesson.difficulty != selectedCategory) {
                    return const SizedBox.shrink();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: VideoLessonCard(
                      lesson: lesson,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerPage(lesson: lesson),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoLesson {
  final int id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final String difficulty;

  VideoLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.difficulty,
  });
}

class VideoLessonCard extends StatelessWidget {
  final VideoLesson lesson;
  final VoidCallback onTap;

  const VideoLessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with play button
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: lightRed,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: primaryRed,
                      size: 60,
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      lesson.duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryRed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      lesson.difficulty,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Video info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lesson.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.visibility, color: Colors.grey, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "${(lesson.id * 123).toString()} vues",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        "4.${(lesson.id % 5) + 5}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
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
}

class VideoPlayerPage extends StatefulWidget {
  final VideoLesson lesson;

  const VideoPlayerPage({super.key, required this.lesson});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  bool isPlaying = false;
  bool isMuted = false;
  double playbackSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isMuted ? Icons.volume_off : Icons.volume_up, color: Colors.white),
            onPressed: () {
              setState(() {
                isMuted = !isMuted;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Video Player Area
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Video placeholder
                  Container(
                    color: lightRed,
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_filled,
                            color: primaryRed,
                            size: 80,
                          ),
                          SizedBox(height: 16),
                          Text(
                            "Lecteur vidéo",
                            style: TextStyle(
                              color: primaryRed,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Play/Pause button overlay
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isPlaying = !isPlaying;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.transparent,
                      child: Center(
                        child: Icon(
                          isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                          color: Colors.white.withOpacity(0.8),
                          size: 80,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Video Info and Controls
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.lesson.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.lesson.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Progress bar
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.3, // 30% progress
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryRed,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("00:30", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(widget.lesson.duration, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Playback controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildControlButton(Icons.replay_10, "Reculer"),
                      _buildControlButton(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        isPlaying ? "Pause" : "Lecture",
                        isMain: true,
                      ),
                      _buildControlButton(Icons.forward_10, "Avancer"),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Speed control
                  Row(
                    children: [
                      const Text("Vitesse:", style: TextStyle(fontSize: 14, color: Colors.black)),
                      const SizedBox(width: 8),
                      ...[0.5, 0.75, 1.0, 1.25, 1.5].map((speed) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                playbackSpeed = speed;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: playbackSpeed == speed ? primaryRed : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "${speed}x",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: playbackSpeed == speed ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, String label, {bool isMain = false}) {
    return Column(
      children: [
        Container(
          width: isMain ? 60 : 50,
          height: isMain ? 60 : 50,
          decoration: BoxDecoration(
            color: isMain ? primaryRed : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isMain ? Colors.white : Colors.black,
            size: isMain ? 30 : 24,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
