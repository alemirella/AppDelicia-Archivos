import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final List<dynamic> cartItems;
  final double total;

  const PaymentMethodScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.cartItems,
    required this.total,
  });

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _metodoPagoSeleccionado = 'Efectivo';
  final TextEditingController _notasController = TextEditingController();
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _metodosPago = [
    {
      'nombre': 'Efectivo',
      'icono': Icons.money,
      'descripcion': 'Pago en efectivo al recibir',
    },
    {
      'nombre': 'Tarjeta',
      'icono': Icons.credit_card,
      'descripcion': 'Pago con tarjeta en el local',
    },
    {
      'nombre': 'Yape',
      'icono': Icons.phone_android,
      'descripcion': 'Transferencia por Yape',
    },
    {
      'nombre': 'Plin',
      'icono': Icons.smartphone,
      'descripcion': 'Transferencia por Plin',
    },
  ];

  Future<void> _confirmarPedido() async {
    setState(() => _isProcessing = true);

    try {
      // Crear el pedido en Firestore
      final pedidoData = {
        'userId': widget.userId,
        'nombreCliente': widget.userName,
        'items': widget.cartItems,
        'total': widget.total,
        'metodoPago': _metodoPagoSeleccionado,
        'notas': _notasController.text.trim(),
        'estado': 'Pendiente',
        'fecha': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('pedidos').add(pedidoData);

      // Vaciar el carrito
      await FirebaseFirestore.instance
          .collection('carritos')
          .doc(widget.userId)
          .update({'items': []});

      if (!mounted) return;

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Pedido realizado con éxito!'),
          backgroundColor: Colors.green,
        ),
      );

      // Regresar a la pantalla anterior (Home)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar pedido: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Método de Pago'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resumen del pedido
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen del Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    ...widget.cartItems.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item['cantidad']}x ${item['nombre']}',
                                  style: const TextStyle(fontSize: 14),
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
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'S/. ${widget.total.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Métodos de pago
            const Text(
              'Selecciona método de pago',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...(_metodosPago.map((metodo) => Card(
                  elevation: _metodoPagoSeleccionado == metodo['nombre'] ? 4 : 1,
                  color: _metodoPagoSeleccionado == metodo['nombre']
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  child: RadioListTile<String>(
                    value: metodo['nombre'],
                    groupValue: _metodoPagoSeleccionado,
                    onChanged: (value) {
                      setState(() => _metodoPagoSeleccionado = value!);
                    },
                    title: Row(
                      children: [
                        Icon(metodo['icono'],
                            color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 12),
                        Text(
                          metodo['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    subtitle: Text(metodo['descripcion']),
                    activeColor: Theme.of(context).colorScheme.secondary,
                  ),
                ))),
            const SizedBox(height: 24),

            // Notas adicionales
            const Text(
              'Notas adicionales (opcional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notasController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: Sin cebolla, extra queso, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Botón confirmar
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _confirmarPedido,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(
                  _isProcessing ? 'Procesando...' : 'Confirmar Pedido',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }
}