# Backend d'Authentification LST

## 🚀 Description

Ce backend simulé permet de tester l'authentification sans avoir à recréer un compte à chaque fois. Il inclut des comptes de test pré-configurés et simule des réponses réseau réalistes.

## 🔑 Comptes de Test Disponibles

### Compte 1
- **Email**: `test@example.com`
- **Mot de passe**: `123456`
- **Nom**: Utilisateur Test
- **XP**: 150
- **Niveau**: Débutant

### Compte 2
- **Email**: `demo@lst.com`
- **Mot de passe**: `demo123`
- **Nom**: Demo LST
- **XP**: 320
- **Niveau**: Intermédiaire

## 📱 Comment utiliser

### 1. Connexion
Utilisez un des comptes de test ci-dessus pour vous connecter :

```dart
final result = await UserService.login('test@example.com', '123456');
```

### 2. Inscription
Pour tester l'inscription, utilisez un email qui n'existe pas encore :

```dart
final result = await UserService.register('nouveau@test.com', 'password', 'Nouveau User');
```

## 🛠️ Architecture

### Fichiers principaux

1. **`backend/auth_service.dart`** - Backend simulé standalone
2. **`lib/services/backend_auth_service.dart`** - Service d'authentification pour l'app
3. **`lib/services/user_service.dart`** - Service utilisateur mis à jour

### Fonctionnalités

- ✅ Connexion avec validation
- ✅ Inscription avec vérification d'email
- ✅ Gestion de session persistante
- ✅ Récupération de profil utilisateur
- ✅ Déconnexion
- ✅ Simulation de délais réseau
- ✅ Messages d'erreur détaillés

## 🧪 Tests

Le backend inclut des tests automatiques dans `backend/auth_service.dart` :

- Connexion avec utilisateur valide
- Connexion avec mot de passe incorrect
- Connexion avec utilisateur inexistant

## 🔄 Mode Développement vs Production

En mode développement (`kDebugMode`), le backend utilise la simulation. En production, il faudrait remplacer les appels par de vraies requêtes HTTP vers votre serveur.

## 📝 Messages d'erreur

- `USER_NOT_FOUND` - Utilisateur non trouvé
- `INVALID_PASSWORD` - Mot de passe incorrect
- `EMAIL_ALREADY_EXISTS` - Email déjà utilisé
- `NETWORK_ERROR` - Erreur de connexion au serveur

## 💾 Persistance

Les sessions sont sauvegardées localement avec SharedPreferences pour maintenir l'utilisateur connecté même après fermeture de l'app.

## 🔧 Personnalisation

Pour ajouter de nouveaux utilisateurs de test, modifiez la map `_users` dans `backend_auth_service.dart` :

```dart
final users = {
  'votre.email@test.com': {
    'id': '3',
    'email': 'votre.email@test.com',
    'password': 'votre_mot_de_passe',
    'name': 'Votre Nom',
    'xp': 0,
    'level': 'Débutant',
  },
  // ... autres utilisateurs
};
```
