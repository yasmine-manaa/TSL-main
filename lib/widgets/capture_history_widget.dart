import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/ai_recognition.dart';

// WIDGET POUR AFFICHER L'HISTORIQUE DES CAPTURES
class CaptureHistoryWidget extends StatefulWidget {
  const CaptureHistoryWidget({super.key});

  @override
  State<CaptureHistoryWidget> createState() => _CaptureHistoryWidgetState();
}

class _CaptureHistoryWidgetState extends State<CaptureHistoryWidget> {
  List<CaptureHistory> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('capture_history') ?? [];
      
      final history = historyJson
          .map((json) => CaptureHistory.fromJson(jsonDecode(json)))
          .toList();
      
      setState(() {
        _history = history;
        _isLoading = false;
      });
      
      print('📚 Historique chargé: ${history.length} captures');
    } catch (e) {
      print('❌ Erreur chargement historique: $e');
      setState(() => _isLoading = false);
    }
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE60012)),
        ),
      );
    }

    if (_history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 10),
            Text(
              "Aucun historique de captures",
              style: TextStyle(
                color: Colors.grey.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Prenez des photos dans la reconnaissance IA\npour voir votre historique ici",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Historique des captures",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "${_history.length} capture${_history.length > 1 ? 's' : ''}",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        
        // Liste des captures
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final capture = _history[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ExpansionTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(capture.imageBase64),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(
                  capture.detectedSign,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      capture.detectedWord,
                      style: TextStyle(
                        color: Colors.grey.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          "Confiance: ${(capture.confidence * 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                            fontSize: 12,
                            color: _getConfidenceColor(capture.confidence),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: _getConfidenceColor(capture.confidence),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                trailing: Text(
                  _formatTimestamp(capture.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.withOpacity(0.6),
                  ),
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Image agrandie
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            base64Decode(capture.imageBase64),
                            height: 200,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Détails
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Icon(Icons.sign_language, color: Color(0xFFE60012)),
                                const SizedBox(height: 4),
                                Text(
                                  capture.detectedSign,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(Icons.translate, color: Color(0xFFE60012)),
                                const SizedBox(height: 4),
                                Text(
                                  capture.detectedWord,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Icon(
                                  Icons.verified,
                                  color: _getConfidenceColor(capture.confidence),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${(capture.confidence * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: _getConfidenceColor(capture.confidence),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Bouton d'action
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/ai_recognition');
                            },
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Nouvelle capture"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE60012),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
