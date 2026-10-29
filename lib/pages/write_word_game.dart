import 'package:flutter/material.dart';
import '../services/user_service.dart';
import 'dart:math';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);
const Color lightRed = Color(0xFFFFE5E5);
const Color mediumRed = Color(0xFFB32D2D);
const Color darkRed = Color(0xFF801818);
const Color lightRed2 = Color(0xFFCC0000);
const Color mediumRed2 = Color(0xFF990000);
const Color successGreen = Color(0xFF4CAF50);
const Color errorOrange = Color(0xFFFF9800);

class WriteWordGamePage extends StatefulWidget {
  const WriteWordGamePage({super.key});

  @override
  State<WriteWordGamePage> createState() => _WriteWordGamePageState();
}

class _WriteWordGamePageState extends State<WriteWordGamePage> with TickerProviderStateMixin {
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
  int _currentQuestionIndex = 0;
  int _totalXP = 0;
  int _correctAnswers = 0;
  bool _gameStarted = false;
  final Random _random = Random();
  
  late AnimationController _bounceController;
  late AnimationController _sparkleController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late AnimationController _celebrationController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _sparkleAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _celebrationAnimation;
  
  final TextEditingController _textController = TextEditingController();
  bool _showResult = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _bounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.bounceOut),
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.easeInOut),
    );
    _shakeAnimation = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _celebrationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    _pulseController.repeat(reverse: true);
    _initializeGame();
  }

  void _initializeGame() {
    final shuffledSigns = List<SignItem>.from(_allSigns)..shuffle(_random);
    _gameQuestions = shuffledSigns.take(6).toList();
  }

  void _startGame() {
    _bounceController.forward();
    _sparkleController.forward();
    _celebrationController.forward();
    
    setState(() {
      _gameStarted = true;
      _currentQuestionIndex = 0;
      _totalXP = 0;
      _correctAnswers = 0;
      _showResult = false;
      _isCorrect = false;
      _textController.clear();
      _initializeGame();
    });
  }

  void _nextQuestion() {
    _bounceController.forward(from: 0.0);
    
    setState(() {
      _currentQuestionIndex++;
      _showResult = false;
      _isCorrect = false;
      _textController.clear();
    });
  }

  void _checkAnswer(String userAnswer) {
    print('🔍 _checkAnswer appelé avec: "$userAnswer"');
    
    if (userAnswer.trim().isEmpty) {
      print('❌ Réponse vide');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.sentiment_dissatisfied, color: Colors.white),
              const SizedBox(width: 8),
              const Text("Veuillez écrire un mot"),
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

    final correctAnswer = _gameQuestions[_currentQuestionIndex].word.toLowerCase().trim();
    final userAnswerClean = userAnswer.toLowerCase().trim();
    
    print('📝 Réponse attendue: "$correctAnswer"');
    print('📝 Réponse utilisateur: "$userAnswerClean"');
    
    // Validation stricte : le mot doit être exactement le même
    final isCorrect = userAnswerClean == correctAnswer;

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      
      if (isCorrect) {
        _totalXP += 10;
        _correctAnswers++;
        _sparkleController.forward(from: 0.0);
        _celebrationController.forward(from: 0.0);
      } else {
        _shakeController.forward(from: 0.0);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        if (_currentQuestionIndex < _gameQuestions.length - 1) {
          _nextQuestion();
        } else {
          _showFinalScore();
        }
      }
    });
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
            color: primaryRed,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _sparkleController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (_sparkleAnimation.value * 0.3),
                  child: Icon(
                    _totalXP >= 40 ? Icons.emoji_events : _totalXP >= 20 ? Icons.star : Icons.star_outline,
                    size: 60,
                    color: _totalXP >= 40 ? primaryRed : _totalXP >= 20 ? primaryRed.withOpacity(0.7) : primaryRed,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              "$_totalXP XP",
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "$_correctAnswers/${_gameQuestions.length} réponses correctes",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getPerformanceMessage(),
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            child: const Text(
              "Rejouer",
              style: TextStyle(color: primaryRed),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text("Quitter"),
          ),
        ],
      ),
    );
  }

  String _getPerformanceMessage() {
    final percentage = (_correctAnswers / _gameQuestions.length) * 100;
    if (percentage >= 80) return "Excellent! Vous écrivez parfaitement les mots!";
    if (percentage >= 60) return "Bon travail! Continuez à pratiquer l'écriture!";
    if (percentage >= 40) return "Pas mal! Encore un peu d'entraînement.";
    return "Continuez à apprendre, vous allez y arriver!";
  }

  void _saveScoreToProfile() async {
    print("Score Écrivez le mot sauvegardé: $_totalXP XP - $_correctAnswers/${_gameQuestions.length}");
    
    // Sauvegarder les XP localement
    try {
      await UserService.saveUserXP(_totalXP);
    } catch (e) {
      print('Erreur lors de la sauvegarde du score: $e');
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Score sauvegardé avec succès!"),
          backgroundColor: primaryRed,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _sparkleController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _celebrationController.dispose();
    _textController.dispose();
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
          "Écrivez le mot",
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
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _sparkleController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _sparkleAnimation.value * 6.28,
                        child: const Icon(
                          Icons.star,
                          color: primaryRed,
                          size: 20,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "$_totalXP XP",
                    style: const TextStyle(
                      color: primaryRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
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
              AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_bounceAnimation.value * 0.3),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withOpacity(0.3),
                            blurRadius: 25,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _celebrationController,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: _celebrationAnimation.value * 6.28,
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Écrivez le mot correspondant!",
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "L'application va vous montrer des signes\net vous devez écrire le mot correspondant",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 2,
                              ),
                            ),
                            child: const Column(
                              children: [
                                Text(
                                  "6 exercices • 10 XP par bonne réponse",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "Maximum: 60 XP",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 30),
              
              SizedBox(
                width: double.infinity,
                height: 65,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_pulseAnimation.value * 0.05),
                      child: Container(
                        decoration: BoxDecoration(
                          color: primaryRed,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryRed.withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _startGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _celebrationController,
                                builder: (context, child) {
                                  return Transform.rotate(
                                    angle: _celebrationAnimation.value * 3.14,
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                "Commencer le jeu",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const SizedBox(height: 20),
              
              AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_bounceAnimation.value * 0.05),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [mediumRed, darkRed],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        "Question ${_currentQuestionIndex + 1}/${_gameQuestions.length}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
              
              AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_bounceAnimation.value * 0.05),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: primaryRed.withOpacity(0.2),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.quiz,
                                color: primaryRed,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Quel est ce mot?",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: primaryRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 800),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Transform.rotate(
                                  angle: (1 - value) * 0.2,
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    decoration: BoxDecoration(
                                      color: primaryRed,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: primaryRed.withOpacity(0.3),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        AnimatedBuilder(
                                          animation: _pulseController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale: 1.0 + (_pulseAnimation.value * 0.1),
                                              child: Container(
                                                width: 160,
                                                height: 160,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.asset(
                                                    _gameQuestions[_currentQuestionIndex].imagePath,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return const Icon(
                                                        Icons.sign_language,
                                                        color: primaryRed,
                                                        size: 80,
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          AnimatedBuilder(
                            animation: _shakeController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_shakeAnimation.value * 0.5, 0),
                                child: TextField(
                                  controller: _textController,
                                  enabled: !_showResult,
                                  onChanged: (value) {
                                    // Ne plus valider automatiquement à chaque changement
                                    // L'utilisateur doit cliquer sur le bouton pour valider
                                  },
                                  onSubmitted: (value) {
                                    // Plus de validation par Entrée - uniquement par bouton
                                  },
                                  decoration: InputDecoration(
                                    hintText: "Écrivez votre réponse...",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: _showResult 
                                          ? (_isCorrect ? successGreen : errorOrange)
                                          : primaryRed,
                                        width: 2,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: primaryRed,
                                        width: 2,
                                      ),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.edit,
                                      color: _showResult 
                                        ? (_isCorrect ? successGreen : errorOrange)
                                        : primaryRed,
                                    ),
                                    suffixIcon: _showResult
                                      ? Icon(
                                          _isCorrect ? Icons.check_circle : Icons.cancel,
                                          color: _isCorrect ? successGreen : errorOrange,
                                        )
                                      : null,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          if (_showResult) ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _isCorrect ? successGreen.withOpacity(0.1) : errorOrange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isCorrect ? successGreen : errorOrange,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isCorrect ? successGreen : errorOrange).withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedBuilder(
                                    animation: _bounceController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: 1.0 + (_bounceAnimation.value * 0.2),
                                        child: Icon(
                                          _isCorrect ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                                          color: _isCorrect ? successGreen : errorOrange,
                                          size: 32,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    children: [
                                      Text(
                                        _isCorrect ? "Correct! +10 XP" : "Essayez encore!",
                                        style: TextStyle(
                                          color: _isCorrect ? successGreen : errorOrange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                      if (_isCorrect)
                                        const Text(
                                          "Super écriture!",
                                          style: TextStyle(
                                            color: successGreen,
                                            fontSize: 14,
                                          ),
                                        ),
                                      if (!_isCorrect)
                                        Text(
                                          "La réponse était: ${_gameQuestions[_currentQuestionIndex].word}",
                                          style: TextStyle(
                                            color: errorOrange,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // Bouton de validation
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  print('🔘 Bouton cliqué - Texte: "${_textController.text}" - _showResult: $_showResult');
                                  if (_textController.text.trim().isNotEmpty && !_showResult) {
                                    print('✅ Validation autorisée');
                                    _checkAnswer(_textController.text);
                                  } else {
                                    print('❌ Validation bloquée - Texte vide: ${_textController.text.trim().isEmpty} - _showResult: $_showResult');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: (_textController.text.trim().isNotEmpty && !_showResult) ? primaryRed : Colors.grey,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: Colors.grey,
                                  disabledForegroundColor: Colors.white70,
                                  elevation: 4,
                                  shadowColor: primaryRed.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.pressed)) {
                                      return darkRed;
                                    }
                                    if (states.contains(WidgetState.hovered)) {
                                      return mediumRed;
                                    }
                                    return null;
                                  }),
                                ),
                                child: const Text(
                                  "Valider ma réponse",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Écrivez le mot complet puis cliquez sur 'Valider ma réponse'",
                              style: TextStyle(
                                color: primaryRed.withOpacity(0.7),
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}

class SignItem {
  final String word;
  final String imagePath;

  SignItem({
    required this.word,
    required this.imagePath,
  });
}
