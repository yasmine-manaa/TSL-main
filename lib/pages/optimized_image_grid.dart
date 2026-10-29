import 'package:flutter/material.dart';

class OptimizedImageGrid extends StatefulWidget {
  const OptimizedImageGrid({super.key});

  @override
  State<OptimizedImageGrid> createState() => _OptimizedImageGridState();
}

class _OptimizedImageGridState extends State<OptimizedImageGrid> {
  // Modèle de données pour les images
  class ImageItem {
    final String id;
    final String title;
    final String imagePath;
    final String category;

    ImageItem({
      required this.id,
      required this.title,
      required this.imagePath,
      required this.category,
    });
  }

  // Liste des images avec chemins vers le dictionnaire_DB
  final List<ImageItem> imageItems = [
    ImageItem(
      id: '1',
      title: 'Carte',
      imagePath: 'dictionnaire_DB/carta-carte.png',
      category: 'Objets',
    ),
    ImageItem(
      id: '2',
      title: 'Maison',
      imagePath: 'dictionnaire_DB/dar-maison.png',
      category: 'Lieux',
    ),
    ImageItem(
      id: '3',
      title: 'Maman',
      imagePath: 'dictionnaire_DB/mama-maman.png',
      category: 'Famille',
    ),
    ImageItem(
      id: '4',
      title: 'Soeur',
      imagePath: 'dictionnaire_DB/okht-soeur.png',
      category: 'Famille',
    ),
    ImageItem(
      id: '5',
      title: 'Septembre',
      imagePath: 'dictionnaire_DB/septembre.png',
      category: 'Mois',
    ),
    ImageItem(
      id: '6',
      title: 'Danser',
      imagePath: 'dictionnaire_DB/yachtah-dance.png',
      category: 'Actions',
    ),
  ];

  // Afficher la boîte modale avec l'image en grand
  void _showImageModal(ImageItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.only(top: 50),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barre de traction
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            
            // Espacement réduit au-dessus de l'image
            const SizedBox(height: 2),
            
            // Image agrandie (250px de hauteur)
            Container(
              width: double.infinity,
              height: 250,
              margin: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.cover, // Remplit la boîte sans déformation
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: 60,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Image non disponible',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Espacement réduit en dessous de l'image
            const SizedBox(height: 2),
            
            // Titre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                item.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Catégorie
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  item.category,
                  style: TextStyle(
                    color: Colors.red[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Grille d\'Images Optimisée',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[600],
        elevation: 0,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(15),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 colonnes
          crossAxisSpacing: 12, // Espacement horizontal
          mainAxisSpacing: 12, // Espacement vertical
          childAspectRatio: 0.7, // Ratio vertical pour plus d'espace
        ),
        itemCount: imageItems.length,
        itemBuilder: (context, index) {
          final item = imageItems[index];
          
          return GestureDetector(
            onTap: () => _showImageModal(item),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image plus grande (180px de hauteur)
                  Expanded(
                    flex: 4, // 4/5 de l'espace pour l'image
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: Image.asset(
                          item.imagePath,
                          fit: BoxFit.cover, // Remplit la cellule sans déformation
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15),
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey[400],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  
                  // Espacement réduit entre image et titre
                  const SizedBox(height: 2),
                  
                  // Section titre (1/5 de l'espace)
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // Catégorie avec espacement minimal
                          const SizedBox(height: 1),
                          
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
