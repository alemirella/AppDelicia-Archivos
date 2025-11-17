import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filtroEstado = 'Todos';

  final List<String> _estados = [
    'Todos',
    'Pendiente',
    'En Preparación',
    'Listo',
    'Entregado',
    'Cancelado',
  ];

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Colors.orange;
      case 'En Preparación':
        return Colors.blue;
      case 'Listo':
        return Colors.green;
      case 'Entregado':
        return Colors.grey;
      case 'Cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'Pendiente':
        return Icons.access_time;
      case 'En Preparación':
        return Icons.restaurant;
      case 'Listo':
        return Icons.check_circle;
      case 'Entregado':
        return Icons.done_all;
      case 'Cancelado':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _actualizarEstado(String pedidoId, String nuevoEstado) async {
    try {
      await FirebaseFirestore.instance
          .collection('pedidos')
          .doc(pedidoId)
          .update({'estado': nuevoEstado});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado actualizado a: $nuevoEstado')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }

  void _mostrarDialogoEstado(String pedidoId, String estadoActual) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cambiar Estado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _estados
              .where((e) => e != 'Todos')
              .map((estado) => ListTile(
                    leading: Icon(
                      _getEstadoIcon(estado),
                      color: _getEstadoColor(estado),
                    ),
                    title: Text(estado),
                    tileColor: estadoActual == estado
                        ? _getEstadoColor(estado).withOpacity(0.1)
                        : null,
                    onTap: () {
                      _actualizarEstado(pedidoId, estado);
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pedidos'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filtro de estados
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _estados.map((estado) {
                  final isSelected = _filtroEstado == estado;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(estado),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _filtroEstado = estado);
                      },
                      selectedColor:
                          estado == 'Todos' ? Colors.blue : _getEstadoColor(estado),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Lista de pedidos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _filtroEstado == 'Todos'
                  ? FirebaseFirestore.instance
                      .collection('pedidos')
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('pedidos')
                      .where('estado', isEqualTo: _filtroEstado)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 100,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _filtroEstado == 'Todos'
                              ? 'No hay pedidos registrados'
                              : 'No hay pedidos con estado: $_filtroEstado',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final pedido = doc.data() as Map<String, dynamic>;
                    final items = pedido['items'] as List<dynamic>;
                    final fecha = pedido['fecha'] as Timestamp?;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              _getEstadoColor(pedido['estado']).withOpacity(0.2),
                          child: Icon(
                            _getEstadoIcon(pedido['estado']),
                            color: _getEstadoColor(pedido['estado']),
                          ),
                        ),
                        title: Text(
                          pedido['nombreCliente'] ?? 'Cliente',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido #${doc.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              fecha != null
                                  ? DateFormat('dd/MM/yyyy HH:mm')
                                      .format(fecha.toDate())
                                  : 'Fecha no disponible',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'S/. ${pedido['total'].toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getEstadoColor(pedido['estado'])
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                pedido['estado'],
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getEstadoColor(pedido['estado']),
                                ),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Productos:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...items.map((item) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item['cantidad']}x ${item['nombre']}',
                                            ),
                                          ),
                                          Text(
                                            'S/. ${(item['precio'] * item['cantidad']).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    const Icon(Icons.payment, size: 20),
                                    const SizedBox(width: 8),
                                    Text('Método: ${pedido['metodoPago']}'),
                                  ],
                                ),
                                if (pedido['notas'] != null &&
                                    pedido['notas'].toString().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.note, size: 20),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text('Notas: ${pedido['notas']}'),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _mostrarDialogoEstado(
                                      doc.id,
                                      pedido['estado'],
                                    ),
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Cambiar Estado'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
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