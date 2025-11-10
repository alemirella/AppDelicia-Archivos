import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogScreen extends StatefulWidget {
  final String? userId;

  const CatalogScreen({super.key, required this.userId});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String? _categoriaSeleccionada;

  Future<void> _agregarAlCarrito(Map<String, dynamic> producto) async {
    if (widget.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para agregar al carrito')),
      );
      return;
    }

    try {
      final carritoRef =
          FirebaseFirestore.instance.collection('carritos').doc(widget.userId);
      final carritoDoc = await carritoRef.get();

      if (carritoDoc.exists) {
        List<dynamic> items = carritoDoc.data()?['items'] ?? [];
        int index = items.indexWhere((item) => item['productoId'] == producto['id']);
        if (index != -1) {
          items[index]['cantidad'] += 1;
        } else {
          items.add({
            'productoId': producto['id'],
            'nombre': producto['nombre'],
            'precio': producto['precio'],
            'cantidad': 1,
          });
        }
        await carritoRef.update({'items': items});
      } else {
        await carritoRef.set({
          'items': [
            {
              'productoId': producto['id'],
              'nombre': producto['nombre'],
              'precio': producto['precio'],
              'cantidad': 1,
            }
          ],
          'userId': widget.userId,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado al carrito')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al agregar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Productos'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _categoriaSeleccionada,
              hint: const Text('Filtrar por categoría'),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.filter_list),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todas las categorías')),
                DropdownMenuItem(value: 'Pan', child: Text('Pan')),
                DropdownMenuItem(value: 'Pasteles', child: Text('Pasteles')),
                DropdownMenuItem(value: 'Galletas', child: Text('Galletas')),
                DropdownMenuItem(value: 'Bebidas', child: Text('Bebidas')),
              ],
              onChanged: (value) => setState(() => _categoriaSeleccionada = value),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _categoriaSeleccionada == null
                  ? FirebaseFirestore.instance.collection('productos').snapshots()
                  : FirebaseFirestore.instance
                      .collection('productos')
                      .where('categoria', isEqualTo: _categoriaSeleccionada)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay productos disponibles'));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7, 
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final producto = {'id': doc.id, ...doc.data() as Map<String, dynamic>};

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(12)),
                            child: AspectRatio(
                              aspectRatio: 1.2, 
                              child: producto['imagenUrl'] != null &&
                                      producto['imagenUrl'].toString().isNotEmpty
                                  ? Image.network(
                                      producto['imagenUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Icon(Icons.image_not_supported, size: 50),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child:
                                          const Icon(Icons.image_not_supported, size: 50),
                                    ),
                            ),
                          ),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    producto['nombre'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    producto['categoria'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'S/. ${double.tryParse(producto['precio'].toString())?.toStringAsFixed(2) ?? '0.00'}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_shopping_cart),
                                        iconSize: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        onPressed: () => _agregarAlCarrito(producto),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
