import 'package:flutter/material.dart';
import 'signup_page.dart';
import 'home_page.dart';
import '../services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  List<String> _savedEmails = [];
  Map<String, String> _emailPasswordMap = {};

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkLoginStatus();
    
    // Ajouter un listener pour l'autocomplétion
    _emailController.addListener(_onEmailChanged);
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;
    
    // Charger tous les emails utilisés précédemment
    final emailsList = prefs.getStringList('used_emails') ?? [];
    final emailPasswords = prefs.getString('email_password_map') ?? '{}';
    
    print('🔍 Chargement credentials - rememberMe: $rememberMe, email: $savedEmail');
    
    setState(() {
      _savedEmails = emailsList;
      _emailPasswordMap = Map<String, String>.from(
        emailPasswords.isNotEmpty ? jsonDecode(emailPasswords) : {}
      );
      
      // Si "Se souvenir de moi" est coché, remplir les champs
      if (rememberMe && savedEmail != null && savedPassword != null) {
        _emailController.text = savedEmail;
        _passwordController.text = savedPassword;
        _rememberMe = true;
        print('✅ Champs remplis automatiquement');
      } else {
        _rememberMe = rememberMe; // Garder l'état de la checkbox
        print('📝 Champs laissés vides, rememberMe: $_rememberMe');
      }
    });
  }

  void _onEmailChanged() {
    final currentText = _emailController.text.toLowerCase().trim();
    
    // COMME GOOGLE : Ne montrer l'autocomplétion que si le texte correspond exactement
    // à un email sauvegardé (pas de suggestions partielles)
    if (_savedEmails.isEmpty || currentText.length < 3) return; // Sécurité : minimum 3 caractères
    
    // Chercher une correspondance EXACTE dans les emails sauvegardés
    for (String savedEmail in _savedEmails) {
      if (savedEmail.toLowerCase() == currentText) {
        // Si correspondance EXACTE, remplir automatiquement
        // Éviter la boucle infinie : vérifier si le texte est déjà le même
        if (_emailController.text.toLowerCase() != savedEmail.toLowerCase()) {
          setState(() {
            _emailController.text = savedEmail;
            _emailController.selection = TextSelection.fromPosition(
              TextPosition(offset: savedEmail.length)
            );
            
            // Remplir le mot de passe si disponible
            if (_emailPasswordMap.containsKey(savedEmail)) {
              _passwordController.text = _emailPasswordMap[savedEmail]!;
            }
          });
        }
        return;
      }
    }
  }

  Future<void> _saveEmailUsage(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ajouter l'email à la liste des emails utilisés SEULEMENT après connexion réussie
    final emailsList = prefs.getStringList('used_emails') ?? [];
    if (!emailsList.contains(email)) {
      emailsList.add(email);
      await prefs.setStringList('used_emails', emailsList);
    }
    
    // Mettre à jour la correspondance email-mot de passe (pour autocomplétion future)
    _emailPasswordMap[email] = password;
    await prefs.setString('email_password_map', jsonEncode(_emailPasswordMap));
    
    print('🔐 Email sauvegardé pour autocomplétion: $email');
  }

  Future<void> _checkLoginStatus() async {
    final isLoggedIn = await UserService.isLoggedIn();
    if (isLoggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    print('🔐 Tentative de connexion - email: $email, rememberMe: $_rememberMe');

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Utiliser le backend pour la connexion
    try {
      final result = await UserService.login(email, password);
      
      if (mounted) {
        if (result['success'] == true) {
          print('✅ Connexion réussie pour: $email');
          
          // Sauvegarder l'utilisation de cet email pour l'autocomplétion
          await _saveEmailUsage(email, password);
          
          // Sauvegarder les identifiants si "Se souvenir de moi" est coché
          if (_rememberMe) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('saved_email', email);
            await prefs.setString('saved_password', password);
            await prefs.setBool('remember_me', true);
            print('💾 Identifiants sauvegardés (remember me)');
          } else {
            // Effacer les identifiants sauvegardés si décoché
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('saved_email');
            await prefs.remove('saved_password');
            await prefs.setBool('remember_me', false);
            print('🗑️ Identifiants effacés (no remember me)');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? "Connexion réussie"),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ),
          );
        } else {
          print('❌ Connexion échouée: ${result['message']}');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? "Email ou mot de passe incorrect"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('💥 Erreur connexion: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGrey,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              const Icon(Icons.accessible, size: 40, color: primaryRed),
              const SizedBox(height: 10),
              const Text(
                "LST Recognition",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: primaryRed,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                "Langue des Signes Tunisienne",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: "Email *",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: "Password *",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Checkbox "Se souvenir de moi"
              Row(
                children: [
                  Checkbox(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    activeColor: primaryRed,
                  ),
                  const Text(
                    "Se souvenir de moi",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(
                    color: primaryRed,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 80),
              const Text(
                "This app is designed to be fully accessible for people with hearing disabilities.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
