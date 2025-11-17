import 'package:flutter/material.dart';
import 'catalog_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';
import 'orders_history_screen.dart'; // Importar la nueva pantalla

class HomeScreen extends StatefulWidget {
  final String? userId;
  final String userName;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      CatalogScreen(userId: widget.userId),
      CartScreen(userId: widget.userId),
      // Si el usuario está logueado, mostrar historial de pedidos, sino mostrar perfil
      widget.userId != null
          ? OrdersHistoryScreen(userId: widget.userId!)
          : ProfileScreen(userId: widget.userId, userName: widget.userName),
      ProfileScreen(userId: widget.userId, userName: widget.userName),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Catálogo',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Carrito',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long),
            label: widget.userId != null ? 'Pedidos' : 'Perfil',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.secondary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}