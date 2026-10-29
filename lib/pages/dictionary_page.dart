import 'package:flutter/material.dart';

const Color primaryRed = Color(0xFFE60012);
const Color bgGrey = Color(0xFFF5F5F5);
const Color lightPink = Color(0xFFFBEDED);

// MODÈLE DE DONNÉES POUR LES SIGNES
class Sign {
  final int id;
  final String title;
  final String arabicWord;
  final String category;
  final String imagePath;
  final String explanationImage;
  final String description;
  final List<String> synonyms;

  Sign({
    required this.id,
    required this.title,
    required this.arabicWord,
    required this.category,
    required this.imagePath,
    required this.explanationImage,
    required this.description,
    required this.synonyms,
  });
}

class DictionaryPage extends StatefulWidget {
  const DictionaryPage({super.key});

  @override
  State<DictionaryPage> createState() => _DictionaryPageState();
}

class _DictionaryPageState extends State<DictionaryPage> {
  String selectedCategory = "Tous";
  String searchQuery = "";
  final TextEditingController searchController = TextEditingController();
  bool _showSignImage = true;

  // DONNÉES DES SIGNES - Extraction des mots arabe/français depuis les noms de dossiers
  final List<Sign> allSigns = [
    Sign(
      id: 1,
      title: "Carte",
      arabicWord: "كارت",
      category: "Objets",
      imagePath: "dictionnaire_DB/carta-carte/1.png",
      explanationImage: "dictionnaire_DB/carta-carte/2.png",
      description: "Signe pour carte",
      synonyms: ["Carte", "Document"],
    ),
    Sign(
      id: 2,
      title: "Maison",
      arabicWord: "دار",
      category: "Lieux",
      imagePath: "dictionnaire_DB/dar-maison/1.png",
      explanationImage: "dictionnaire_DB/dar-maison/2.png",
      description: "Signe pour maison",
      synonyms: ["Maison", "Domicile", "Chez soi"],
    ),
    Sign(
      id: 3,
      title: "Maman",
      arabicWord: "أمي",
      category: "Famille",
      imagePath: "dictionnaire_DB/ommi-maman/1.png",
      explanationImage: "dictionnaire_DB/ommi-maman/2.png",
      description: "Signe pour maman",
      synonyms: ["Mère", "Maman"],
    ),
    Sign(
      id: 4,
      title: "Soeur",
      arabicWord: "أختي",
      category: "Famille",
      imagePath: "dictionnaire_DB/okhti-soeur/1.png",
      explanationImage: "dictionnaire_DB/okhti-soeur/2.png",
      description: "Signe pour soeur",
      synonyms: ["Soeur", "Sœur"],
    ),
    Sign(
      id: 5,
      title: "Septembre",
      arabicWord: "سبتمبر",
      category: "Mois",
      imagePath: "dictionnaire_DB/septembre-septembre/1.png",
      explanationImage: "dictionnaire_DB/septembre-septembre/2.png",
      description: "Signe pour septembre",
      synonyms: ["Septembre", "Mois 9"],
    ),
    Sign(
      id: 6,
      title: "Danser",
      arabicWord: "يختاح",
      category: "Actions",
      imagePath: "dictionnaire_DB/yachtah-dance/1.png",
      explanationImage: "dictionnaire_DB/yachtah-dance/2.png",
      description: "Signe pour danser",
      synonyms: ["Danse", "Bouger", "Yachtah"],
    ),
    Sign(
      id: 7,
      title: "Municipalité",
      arabicWord: "بلدية",
      category: "Lieux",
      imagePath: "dictionnaire_DB/baladiya-municipalite/1.png",
      explanationImage: "dictionnaire_DB/baladiya-municipalite/2.png",
      description: "Signe pour municipalité",
      synonyms: ["Municipalité", "Baladiya"],
    ),
    Sign(
      id: 8,
      title: "Centre",
      arabicWord: "مركز",
      category: "Lieux",
      imagePath: "dictionnaire_DB/centre-centre/1.png",
      explanationImage: "dictionnaire_DB/centre-centre/2.png",
      description: "Signe pour centre",
      synonyms: ["Centre", "Milieu"],
    ),
    Sign(
      id: 9,
      title: "Nom",
      arabicWord: "اسم",
      category: "Personnes",
      imagePath: "dictionnaire_DB/esmi-nom/1.png",
      explanationImage: "dictionnaire_DB/esmi-nom/2.png",
      description: "Signe pour nom",
      synonyms: ["Nom", "Esmi"],
    ),
    Sign(
      id: 10,
      title: "Élection",
      arabicWord: "انتخاب",
      category: "Actions",
      imagePath: "dictionnaire_DB/intikhabet-election/1.png",
      explanationImage: "dictionnaire_DB/intikhabet-election/2.png",
      description: "Signe pour élection",
      synonyms: ["Élection", "Vote", "Intikhabet"],
    ),
    Sign(
      id: 11,
      title: "Grand-mère",
      arabicWord: "جدة",
      category: "Famille",
      imagePath: "dictionnaire_DB/jadda-grand mere/1.png",
      explanationImage: "dictionnaire_DB/jadda-grand mere/2.png",
      description: "Signe pour grand-mère",
      synonyms: ["Grand-mère", "Jadda"],
    ),
    Sign(
      id: 12,
      title: "Café",
      arabicWord: "قهوة",
      category: "Lieux",
      imagePath: "dictionnaire_DB/kahwa-cafe/1.png",
      explanationImage: "dictionnaire_DB/kahwa-cafe/2.png",
      description: "Signe pour café",
      synonyms: ["Café", "Kahwa"],
    ),
    Sign(
      id: 13,
      title: "Travail",
      arabicWord: "خدمة",
      category: "Actions",
      imagePath: "dictionnaire_DB/khedma-travail/1.png",
      explanationImage: "dictionnaire_DB/khedma-travail/2.png",
      description: "Signe pour travail",
      synonyms: ["Travail", "Khedma", "Emploi"],
    ),
    Sign(
      id: 14,
      title: "Directeur",
      arabicWord: "مدير",
      category: "Personnes",
      imagePath: "dictionnaire_DB/moudir-directeur/1.png",
      explanationImage: "dictionnaire_DB/moudir-directeur/2.png",
      description: "Signe pour directeur",
      synonyms: ["Directeur", "Moudir", "Chef"],
    ),
    Sign(
      id: 15,
      title: "Arme",
      arabicWord: "سلاح",
      category: "Objets",
      imagePath: "dictionnaire_DB/sleh-arme/1.png",
      explanationImage: "dictionnaire_DB/sleh-arme/2.png",
      description: "Signe pour arme",
      synonyms: ["Arme", "Sleh"],
    ),
    Sign(
      id: 16,
      title: "Taxi",
      arabicWord: "تاكسي",
      category: "Transport",
      imagePath: "dictionnaire_DB/taxi-taxi/1.png",
      explanationImage: "dictionnaire_DB/taxi-taxi/2.png",
      description: "Signe pour taxi",
      synonyms: ["Taxi", "Transport"],
    ),
    Sign(
      id: 17,
      title: "Aider",
      arabicWord: "ساعد",
      category: "Actions",
      imagePath: "dictionnaire_DB/yaawen-aider/1.png",
      explanationImage: "dictionnaire_DB/yaawen-aider/2.png",
      description: "Signe pour aider",
      synonyms: ["Aider", "Yaawen", "Assistance"],
    ),
    Sign(
      id: 18,
      title: "Entendant",
      arabicWord: "سامع",
      category: "Personnes",
      imagePath: "dictionnaire_DB/yasmaa-entendant/1.png",
      explanationImage: "dictionnaire_DB/yasmaa-entendant/2.png",
      description: "Signe pour entendant",
      synonyms: ["Entendant", "Yasmaa", "Personne entendante"],
    ),
    Sign(
      id: 19,
      title: "Faux",
      arabicWord: "غالط",
      category: "Actions",
      imagePath: "dictionnaire_DB/ghalet-faux/1.png",
      explanationImage: "dictionnaire_DB/ghalet-faux/2.png",
      description: "Signe pour faux",
      synonyms: ["Faux", "Ghalet", "Incorrect"],
    ),
    Sign(
      id: 20,
      title: "Objectif",
      arabicWord: "هدف",
      category: "Actions",
      imagePath: "dictionnaire_DB/hadaf-objectif/1.png",
      explanationImage: "dictionnaire_DB/hadaf-objectif/2.png",
      description: "Signe pour objectif",
      synonyms: ["Objectif", "Hadaf", "But"],
    ),
    Sign(
      id: 22,
      title: "Handicap",
      arabicWord: "إعاقة",
      category: "Personnes",
      imagePath: "dictionnaire_DB/iaka-handicap/1.png",
      explanationImage: "dictionnaire_DB/iaka-handicap/2.png",
      description: "Signe pour handicap",
      synonyms: ["Handicap", "Iaka", "Invalidité"],
    ),
    Sign(
      id: 23,
      title: "Bien",
      arabicWord: "خير",
      category: "Actions",
      imagePath: "dictionnaire_DB/labes-bien/1.png",
      explanationImage: "dictionnaire_DB/labes-bien/2.png",
      description: "Signe pour bien",
      synonyms: ["Bien", "Labes", "Bon"],
    ),
    Sign(
      id: 24,
      title: "Sponsor",
      arabicWord: "راعي",
      category: "Personnes",
      imagePath: "dictionnaire_DB/sponsor-sponsor/1.png",
      explanationImage: "dictionnaire_DB/sponsor-sponsor/2.png",
      description: "Signe pour sponsor",
      synonyms: ["Sponsor", "Ra'i", "Mécène"],
    ),
  ];

  List<String> get categories {
    return ["Tous", "Objets", "Lieux", "Famille", "Mois", "Actions", "Personnes", "Transport"];
  }

  // Fonction pour extraire le mot et la langue depuis le nom du dossier
  Map<String, String> _extractWordsFromPath(String imagePath) {
    // Extraire le nom du dossier (ex: "carta-carte" -> ["carta", "carte"])
    final folderName = imagePath.split('/').last; // Récupère "carta-carte"
    final parts = folderName.split('-'); // Sépare ["carta", "carte"]
    
    if (parts.length >= 2) {
      return {
        'tunisien': parts[0], // Premier mot = tunisien
        'francais': parts[1],  // Deuxième mot = français
      };
    }
    return {
      'tunisien': '',
      'francais': '',
    };
  }

  List<Sign> get filteredSigns {
    return allSigns.where((sign) {
      final matchCategory = selectedCategory == "Tous" || sign.category == selectedCategory;
      final matchSearch = sign.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
          sign.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchCategory && matchSearch;
    }).toList();
  }

  void _showSignDetail(Sign sign) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Drapeau Tunisie + mot tunisien
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              '🇹🇳',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ": ${_extractWordsFromPath(sign.imagePath)['tunisien'] ?? ''}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primaryRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Drapeau France + mot français
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Text(
                              '🇫🇷',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ": ${_extractWordsFromPath(sign.imagePath)['francais'] ?? ''}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  sign.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: lightPink,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sign.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: primaryRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Onglets pour basculer entre les images
                Container(
                  decoration: BoxDecoration(
                    color: bgGrey,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Onglets
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showSignImage = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: _showSignImage ? primaryRed : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(15),
                                      topRight: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    "Signe",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _showSignImage ? Colors.white : primaryRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _showSignImage = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: !_showSignImage ? primaryRed : Colors.transparent,
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(15),
                                      topLeft: Radius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    "Explication",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: !_showSignImage ? Colors.white : primaryRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Image
                      Container(
                        width: double.infinity,
                        height: 250,
                        decoration: BoxDecoration(
                          color: bgGrey,
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                          child: Image.asset(
                            _showSignImage ? sign.imagePath : sign.explanationImage,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 80,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _showSignImage ? "Image du signe non trouvée" : "Image d'explication non trouvée",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Description",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  sign.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Synonymes",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: sign.synonyms
                      .map(
                        (synonym) => Chip(
                          label: Text(synonym),
                          backgroundColor: lightPink,
                          labelStyle: const TextStyle(color: primaryRed),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
          "Dictionnaire LST",
          style: TextStyle(
            color: primaryRed,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          // TITRE ET SOUS-TITRE
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Dictionnaire LST",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Explorer ${filteredSigns.length} signes de la langue des signes tunisienne",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // BARRE DE RECHERCHE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Rechercher un signe...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Colors.grey),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // ONGLETS DE CATÉGORIES
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryRed : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? primaryRed : Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),

          // GRILLE DE SIGNES
          Expanded(
            child: filteredSigns.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Aucun signe trouvé",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(15),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: filteredSigns.length,
                    itemBuilder: (context, index) {
                      final sign = filteredSigns[index];
                      return GestureDetector(
                        onTap: () => _showSignDetail(sign),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
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
                              // IMAGE AGRANDIE
                              Container(
                                width: double.infinity,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: bgGrey,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(15),
                                  ),
                                  child: Stack(
                                    children: [
                                      Image.asset(
                                        sign.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Center(
                                            child: Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey[400],
                                            ),
                                          );
                                        },
                                      ),
                                      // Drapeau
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          width: 24,
                                          height: 16,
                                          decoration: BoxDecoration(
                                            color: Colors.blue,
                                            borderRadius: BorderRadius.circular(2),
                                            border: Border.all(color: Colors.white, width: 1),
                                          ),
                                          child: const Center(
                                            child: Text(
                                              '🇫🇷',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // INFO REDUITE
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      sign.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      sign.category,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: primaryRed,
                                        fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}