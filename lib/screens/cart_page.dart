import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _cartItems = [];
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  void _fetchCartItems() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('Utilisateur non connecté.');
        return;
      }

      DocumentReference cartRef =
          FirebaseFirestore.instance.collection('carts').doc(user.uid);
      print("cartRef : $cartRef");

      DocumentSnapshot cartDoc = await cartRef.get();


      if (cartDoc.exists) {
        List<dynamic> items = cartDoc['items'];

        print("items : $items");

        // Récupérer les détails de chaque vêtement
        List<Map<String, dynamic>> cartItems = [];

        for (var item in items) {
          String clotheId = item['clotheId'];

          //print("clotheId : $clotheId");

          DocumentSnapshot clotheDoc = await FirebaseFirestore.instance
              .collection('clothes')
              .doc(clotheId)
              .get();
          print("clotheDoc : $clotheDoc");

          if (clotheDoc.exists) {
            Map<String, dynamic> clotheData =
                clotheDoc.data() as Map<String, dynamic>;
            clotheData['clotheId'] = clotheId;
            cartItems.add(clotheData);
          }
        }

        // Calculer le total
        double total = 0.0;
        for (var item in cartItems) {
          total += item['price'];
        }

        setState(() {
          _cartItems = cartItems;
          _totalPrice = total;
        });
      } else {
        setState(() {
          _cartItems = [];
          _totalPrice = 0.0;
        });
      }
    } catch (e) {
      print('Erreur lors de la récupération du panier : $e');
    }
  }

  void _removeFromCart(String clotheId) async {
    try {
      User? user = _auth.currentUser;
      if (user == null) {
        print('Utilisateur non connecté.');
        return;
      }

      DocumentReference cartRef =
          FirebaseFirestore.instance.collection('carts').doc(user.uid);

      DocumentSnapshot cartDoc = await cartRef.get();

      if (cartDoc.exists) {
        List<dynamic> items = cartDoc['items'];

        items.removeWhere((item) => item['clotheId'] == clotheId);

        await cartRef.update({
          'items': items,
        });

        // Mettre à jour l'affichage
        _fetchCartItems();
      }
    } catch (e) {
      print('Erreur lors de la suppression du produit : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cartItems.isEmpty) {
      return Center(
        child: Text('Votre panier est vide.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 30.0),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                var item = _cartItems[index];
      
                return ListTile(
                  leading: Image.network(
                    item['imageUrl'],
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  title: Text(item['title']),
                  subtitle: Text('Taille : ${item['size']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${item['price']} €'),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          _removeFromCart(item['clotheId']);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total : ${_totalPrice.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
