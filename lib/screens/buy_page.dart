import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_detail_page.dart'; 

class BuyPage extends StatefulWidget {
  const BuyPage({Key? key}) : super(key: key);

  @override
  _BuyPageState createState() => _BuyPageState();
}

class _BuyPageState extends State<BuyPage> {
  final CollectionReference _clothesCollection =
      FirebaseFirestore.instance.collection('clothes');

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _clothesCollection.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Erreur : ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Récupération des documents
        final clothes = snapshot.data!.docs;

        return ListView.builder(
          itemCount: clothes.length,
          itemBuilder: (context, index) {
            // Données du vêtement
            var data = clothes[index].data() as Map<String, dynamic>;

            return ListTile(
              leading: Image.network(
                data['imageUrl'],
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              ),

              title: Text(data['title']),
              subtitle: Text('Taille: ${data['size']}'),
              trailing: Text('${data['price']} €'),
              onTap: () {
                // Naviguer vers la page de détail (US#3)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailPage(
                      clotheId: clothes[index].id,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
