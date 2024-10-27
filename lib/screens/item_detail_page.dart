import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ItemDetailPage extends StatefulWidget {
  final String clotheId;

  const ItemDetailPage({Key? key, required this.clotheId}) : super(key: key);

  @override
  _ItemDetailPageState createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  final CollectionReference _clothesCollection =
      FirebaseFirestore.instance.collection('clothes');

  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _clotheData;

  @override
  void initState() {
    super.initState();
    _fetchClotheDetails();
  }

  void _fetchClotheDetails() async {
    try {
      DocumentSnapshot doc =
          await _clothesCollection.doc(widget.clotheId).get();
      if (doc.exists) {
        setState(() {
          _clotheData = doc.data() as Map<String, dynamic>;
        });
      } else {
        print('Le vêtement n\'existe pas.');
      }
    } catch (e) {
      print('Erreur lors de la récupération des détails : $e');
    }
  }

  void _addToCart() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('Utilisateur non connecté.');
        return;
      }

      // Référence à la collection 'carts' pour l'utilisateur actuel
      DocumentReference cartRef =
          FirebaseFirestore.instance.collection('carts').doc(user.uid);

      // Récupérer le panier actuel
      DocumentSnapshot cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        // Mettre à jour le panier existant
        await cartRef.update({
          'items': FieldValue.arrayUnion([{"clotheId": widget.clotheId}]),
        });
      } else {
        // Créer un nouveau panier
        await cartRef.set({
          'items': [{"clotheId": widget.clotheId}],
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Article ajouté au panier.')),
      );
    } catch (e) {
      print('Erreur lors de l\'ajout au panier : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_clotheData == null) {
      // Afficher un indicateur de chargement
      return Scaffold(
        appBar: AppBar(
          title: Text('Détail du vêtement'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Détail du vêtement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.network(
                    _clotheData!['imageUrl'],
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _clotheData!['title'],
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Catégorie : ${_clotheData!['category']}'),
                  Text('Taille : ${_clotheData!['size']}'),
                  Text('Marque : ${_clotheData!['brand']}'),
                  SizedBox(height: 8),
                  Text(
                    '${_clotheData!['price']} €',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Bouton Retour
                    Navigator.pop(context);
                  },
                  child: Text('Retour'),
                ),
                ElevatedButton(
                  onPressed: _addToCart,
                  child: Text('Ajouter au panier'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
