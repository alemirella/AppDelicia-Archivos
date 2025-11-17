import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'admin_orders_screen.dart'; // Importar la nueva pantalla

class AdminScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AdminScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _nombre = TextEditingController();
  final TextEditingController _precio = TextEditingController();
  final TextEditingController _descripcion = TextEditingController();
  final TextEditingController _imagenUrl = TextEditingController();

  String? _categoriaSeleccionada;
  String? _idSeleccionado;

  final List<String> _categorias = [
    'Pan',
    'Pasteles',
    'Galletas',
    'Bebidas',
  ];

  Future<void> _crearProducto() async {
    if (!_validarCampos()) return;

    final datos = {
      'nombre': _nombre.text.trim(),
      'categoria': _categoriaSeleccionada,
      'precio': double.tryParse(_precio.text) ?? 0.0,
      'descripcion': _descripcion.text.trim(),
      'imagenUrl': _imagenUrl.text.trim(),
      'disponible': true,
      'fechaCreacion': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('productos').add(datos);
      _limpiarFormulario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto agregado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al crear producto: $e')),
      );
    }
  }

  Future<void> _actualizarProducto(String id) async {
    if (!_validarCampos()) return;

    final datos = {
      'nombre': _nombre.text.trim(),
      'categoria': _categoriaSeleccionada,
      'precio': double.tryParse(_precio.text) ?? 0.0,
      'descripcion': _descripcion.text.trim(),
      'imagenUrl': _imagenUrl.text.trim(),
    };

    try {
      await FirebaseFirestore.instance.collection('productos').doc(id).update(datos);
      _limpiarFormulario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto actualizado exitosamente')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }

  Future<void> _eliminarProducto(String id) async {
    try {
      await FirebaseFirestore.instance.collection('productos').doc(id).delete();
      _limpiarFormulario();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Producto eliminado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  void _limpiarFormulario() {
    setState(() {
      _nombre.clear();
      _precio.clear();
      _descripcion.clear();
      _imagenUrl.clear();
      _categoriaSeleccionada = null;
      _idSeleccionado = null;
    });
  }

  bool _validarCampos() {
    if (_nombre.text.isEmpty ||
        _precio.text.isEmpty ||
        _categoriaSeleccionada == null ||
        _imagenUrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos obligatorios')),
      );
      return false;
    }

    if (double.tryParse(_precio.text) == null ||
        double.tryParse(_precio.text)! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El precio debe ser un número válido mayor que cero')),
      );
      return false;
    }

    return true;
  }

  void _cerrarSesion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Deseas cerrar sesión?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  // Nueva función para ir a la pantalla de pedidos
  void _verPedidos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminOrdersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Admin - ${widget.userName}'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          // Botón para ver pedidos
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: _verPedidos,
            tooltip: 'Ver Pedidos',
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _cerrarSesion),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de acceso rápido a pedidos
            Card(
              elevation: 3,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              child: InkWell(
                onTap: _verPedidos,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gestión de Pedidos',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ver y administrar todos los pedidos',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 2),
            const SizedBox(height: 16),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _idSeleccionado == null ? 'Agregar Nuevo Producto' : 'Editar Producto',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nombre,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del producto *',
                        prefixIcon: Icon(Icons.bakery_dining),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _categoriaSeleccionada,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        prefixIcon: Icon(Icons.category),
                        border: OutlineInputBorder(),
                      ),
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem(value: categoria, child: Text(categoria));
                      }).toList(),
                      onChanged: (value) => setState(() => _categoriaSeleccionada = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _precio,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Precio (S/.) *',
                        prefixIcon: Icon(Icons.attach_money),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descripcion,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imagenUrl,
                      decoration: const InputDecoration(
                        labelText: 'Enlace de Imagen *',
                        prefixIcon: Icon(Icons.image),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_idSeleccionado == null) {
                                _crearProducto();
                              } else {
                                _actualizarProducto(_idSeleccionado!);
                              }
                            },
                            icon: Icon(_idSeleccionado == null ? Icons.add : Icons.save),
                            label: Text(_idSeleccionado == null ? 'Agregar' : 'Actualizar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _idSeleccionado == null ? Colors.green : Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        if (_idSeleccionado != null) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _limpiarFormulario,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancelar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            const Text('Lista de Productos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('productos').orderBy('fechaCreacion', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay productos registrados'));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final producto = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: producto['imagenUrl'] != null &&
                                  producto['imagenUrl'].toString().isNotEmpty
                              ? Image.network(
                                  producto['imagenUrl'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                        ),
                        title: Text(producto['nombre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('S/. ${producto['precio'].toStringAsFixed(2)}'),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                setState(() {
                                  _idSeleccionado = doc.id;
                                  _nombre.text = producto['nombre'];
                                  _categoriaSeleccionada = producto['categoria'];
                                  _precio.text = producto['precio'].toString();
                                  _descripcion.text = producto['descripcion'] ?? '';
                                  _imagenUrl.text = producto['imagenUrl'] ?? '';
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarProducto(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precio.dispose();
    _descripcion.dispose();
    _imagenUrl.dispose();
    super.dispose();
  }
}