import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'dart:math';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);
const Color lightPink = Color(0xFFFBEDED);

class SignItem {
  final String word;
  final String imagePath;

  SignItem({
    required this.word,
    required this.imagePath,
  });
}

class FindImageGame extends StatefulWidget {
  const FindImageGame({super.key});

  @override
  State<FindImageGame> createState() => _FindImageGameState();
}

class _FindImageGameState extends State<FindImageGame> {
  final List<SignItem> _allSigns = [
    SignItem(word: "Carte", imagePath: "dictionnaire_DB/carta-carte/1.png"),
    SignItem(word: "Maison", imagePath: "dictionnaire_DB/dar-maison/1.png"),
    SignItem(word: "Maman", imagePath: "dictionnaire_DB/ommi-maman/1.png"),
    SignItem(word: "Soeur", imagePath: "dictionnaire_DB/okhti-soeur/1.png"),
    SignItem(word: "Danser", imagePath: "dictionnaire_DB/yachtah-dance/1.png"),
    SignItem(word: "Septembre", imagePath: "dictionnaire_DB/septembre-septembre/1.png"),
    SignItem(word: "Municipalité", imagePath: "dictionnaire_DB/baladiya-municipalite/1.png"),
    SignItem(word: "Centre", imagePath: "dictionnaire_DB/centre-centre/1.png"),
    SignItem(word: "Nom", imagePath: "dictionnaire_DB/esmi-nom/1.png"),
    SignItem(word: "Élection", imagePath: "dictionnaire_DB/intikhabet-election/1.png"),
    SignItem(word: "Grand-mère", imagePath: "dictionnaire_DB/jadda-grand mere/1.png"),
    SignItem(word: "Café", imagePath: "dictionnaire_DB/kahwa-cafe/1.png"),
    SignItem(word: "Travail", imagePath: "dictionnaire_DB/khedma-travail/1.png"),
    SignItem(word: "Directeur", imagePath: "dictionnaire_DB/moudir-directeur/1.png"),
    SignItem(word: "Arme", imagePath: "dictionnaire_DB/sleh-arme/1.png"),
    SignItem(word: "Taxi", imagePath: "dictionnaire_DB/taxi-taxi/1.png"),
    SignItem(word: "Aider", imagePath: "dictionnaire_DB/yaawen-aider/1.png"),
    SignItem(word: "Entendant", imagePath: "dictionnaire_DB/yasmaa-entendant/1.png"),
    SignItem(word: "Faux", imagePath: "dictionnaire_DB/ghalet-faux/1.png"),
    SignItem(word: "Objectif", imagePath: "dictionnaire_DB/hadaf-objectif/1.png"),
    SignItem(word: "Handicap", imagePath: "dictionnaire_DB/iaka-handicap/1.png"),
    SignItem(word: "Bien", imagePath: "dictionnaire_DB/labes-bien/1.png"),
    SignItem(word: "Sponsor", imagePath: "dictionnaire_DB/sponsor-sponsor/1.png"),
  ];

  late List<SignItem> _gameQuestions;
  late List<String> _currentImages;
  late int _correctImageIndex;
  
  int _currentQuestionIndex = 0;
  int _totalXP = 0;
  int _correctAnswers = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  int? _selectedImageIndex;
  bool _gameStarted = false;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Ne pas initialiser ici, laisser _startGame choisir aléatoirement
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _currentQuestionIndex = 0;
      _totalXP = 0;
      _correctAnswers = 0;
      _showResult = false;
      _isCorrect = false;
      _selectedImageIndex = null;
      
      // Utiliser une nouvelle graine aléatoire basée sur le temps pour un vrai aléatoire
      final randomWithSeed = Random(DateTime.now().millisecondsSinceEpoch);
      final shuffledSigns = List<SignItem>.from(_allSigns)..shuffle(randomWithSeed);
      _gameQuestions = shuffledSigns.take(6).toList();
      
      _setupQuestion();
    });
  }

  void _setupQuestion() {
    final questionSign = _gameQuestions[_currentQuestionIndex];
    
    // Créer une liste de toutes les options sauf la bonne réponse
    final otherOptions = _allSigns.where((sign) => sign.word != questionSign.word).toList();
    
    // Utiliser une graine aléatoire différente pour les options
    final optionsRandom = Random(DateTime.now().millisecondsSinceEpoch + _currentQuestionIndex);
    otherOptions.shuffle(optionsRandom);
    final randomOptions = otherOptions.take(3).toList();
    
    // Ajouter la bonne réponse et mélanger les 4 options avec une autre graine
    final allOptions = [questionSign, ...randomOptions];
    final finalRandom = Random(DateTime.now().millisecondsSinceEpoch + _currentQuestionIndex + 100);
    allOptions.shuffle(finalRandom);
    
    _correctImageIndex = allOptions.indexOf(questionSign);
    _currentImages = allOptions.map((sign) => sign.imagePath).toList();
    
    setState(() {
      _selectedImageIndex = null;
      _showResult = false;
      _isCorrect = false;
    });
  }

  void _selectImage(int index) {
    if (_showResult || _selectedImageIndex != null) return;
    
    setState(() {
      _selectedImageIndex = index;
    });
  }

  void _checkAnswer() {
    if (_selectedImageIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sentiment_dissatisfied, color: Colors.white),
              const SizedBox(width: 8),
              const Text("Veuillez sélectionner une image"),
            ],
          ),
          backgroundColor: primaryRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isCorrect = _selectedImageIndex == _correctImageIndex;
    
    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      
      if (isCorrect) {
        _totalXP += 10;
        _correctAnswers++;
      }
    });

    _saveScoreToProfile();

    // Passer automatiquement à la question suivante après 1.5 secondes
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        if (_currentQuestionIndex < _gameQuestions.length - 1) {
          _nextQuestion();
        } else {
          _showFinalScore();
        }
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _gameQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedImageIndex = null;
        _showResult = false;
        _isCorrect = false;
      });
      _setupQuestion();
    } else {
      _showFinalScore();
    }
  }

  void _showFinalScore() {
    _saveScoreToProfile();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "Partie terminée!",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryRed,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: primaryRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "$_correctAnswers/${_gameQuestions.length}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: primaryRed,
                    ),
                  ),
                  const Text(
                    "réponses correctes",
                    style: TextStyle(
                      fontSize: 12,
                      color: primaryRed,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "XP gagnés: $_totalXP",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryRed,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Score moyen: ${(_totalXP / _gameQuestions.length).toStringAsFixed(1)} XP/question",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _gameStarted = false;
              });
            },
            child: const Text(
              "Rejouer",
              style: TextStyle(
                color: primaryRed,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text(
              "Retour",
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveScoreToProfile() async {
    try {
      await UserService.saveUserXP(_totalXP);
    } catch (e) {
      print('Erreur lors de la sauvegarde du score: $e');
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          "Trouvez l'image",
          style: TextStyle(
            color: primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          if (_gameStarted)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: lightPink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: primaryRed,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "$_totalXP XP",
                      style: const TextStyle(
                        color: primaryRed,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!_gameStarted) ...[
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryRed, Color(0xFFCC0000)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Trouvez l'image",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: primaryRed,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "L'application va vous proposer un mot\net vous devez sélectionner la bonne image",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: lightPink,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: primaryRed.withOpacity(0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.star,
                            color: primaryRed,
                            size: 30,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "6 questions",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryRed,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "10 XP par bonne réponse",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Maximum: 60 XP",
                            style: TextStyle(
                              fontSize: 16,
                              color: primaryRed,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _startGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 8,
                        shadowColor: primaryRed.withOpacity(0.3),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "Commencer",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Question counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: primaryRed,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      _gameQuestions[_currentQuestionIndex].word,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Trouvez l'image qui correspond à ce signe",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Images grid
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.0,
                ),
                itemCount: _currentImages.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedImageIndex == index;
                  final isCorrect = _showResult && index == _correctImageIndex;
                  final isWrong = _showResult && isSelected && index != _correctImageIndex;
                  
                  return GestureDetector(
                    onTap: () => _selectImage(index),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? (isCorrect ? Colors.green : (isWrong ? Colors.red : primaryRed))
                            : Colors.black26,
                          width: isSelected ? 3 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                              ? (isCorrect ? Colors.green.withOpacity(0.3) : (isWrong ? Colors.red.withOpacity(0.2) : primaryRed.withOpacity(0.3)))
                              : Colors.black.withOpacity(0.1),
                            blurRadius: isSelected ? 8 : 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: isSelected 
                            ? (isCorrect ? Colors.green.withOpacity(0.1) : (isWrong ? Colors.red.withOpacity(0.1) : primaryRed.withOpacity(0.1)))
                            : Colors.white,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // Image
                              Container(
                                width: double.infinity,
                                height: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.asset(
                                    _currentImages[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image,
                                              size: 40,
                                              color: isSelected 
                                                ? (isCorrect ? Colors.green : (isWrong ? Colors.red : primaryRed))
                                                : Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              "Image ${index + 1}",
                                              style: TextStyle(
                                                color: isSelected 
                                                  ? (isCorrect ? Colors.green : (isWrong ? Colors.red : primaryRed))
                                                  : Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              // Overlay for correct/wrong answers
                              if (_showResult && index == _correctImageIndex)
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.green.withOpacity(0.2),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 50,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Correct!",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_showResult && isSelected && index != _correctImageIndex)
                                Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.red.withOpacity(0.2),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 50,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        "Essai encore!",
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Action buttons
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: _selectedImageIndex != null ? _checkAnswer : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedImageIndex != null ? primaryRed : Colors.grey[300]!,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: _selectedImageIndex != null ? 8 : 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedImageIndex != null ? Icons.check_circle : Icons.help_outline,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Valider",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}