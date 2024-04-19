import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pokemon Cards',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PokemonNavigation()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/pokemon.png', // Replace with your image path
              width: 400,
              height: 400,
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class PokemonNavigation extends StatefulWidget {
  @override
  _PokemonNavigationState createState() => _PokemonNavigationState();
}

class _PokemonNavigationState extends State<PokemonNavigation> {
  int _selectedIndex = 0;
  PageController _pageController = PageController();
  List<dynamic> cartItems = [];

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  void buyNow() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BuyNowDialog(
          totalPrice: calculateTotalPrice(),
          confirmPayment: performPayment,
        );
      },
    );
  }

  double calculateTotalPrice() {
    double totalPrice = 0;
    for (var item in cartItems) {
      totalPrice +=
      (item['tcgplayer']?['prices']?['holofoil']?['market'] ?? 0);
    }
    return totalPrice;
  }

  void performPayment(double amount) {
    clearCart();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Thank you! Payment Successful.'),
      backgroundColor: Colors.green,
    ));
  }

  void clearCart() {
    setState(() {
      cartItems.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sneha Pokemon Cards'),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          PokemonList(addToCart: addToCart, showDetails: _showPokemonDetails),
          CartList(cartItems: cartItems, removeCartItem: removeCartItem, addToCart: addToCart),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
      floatingActionButton: cartItems.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: buyNow,
        label: Text('Buy Now'),
        icon: Icon(Icons.payment),
      )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void addToCart(dynamic pokemon) {
    setState(() {
      cartItems.add(pokemon);
    });
  }

  void removeCartItem(dynamic pokemon) {
    setState(() {
      cartItems.remove(pokemon);
    });
  }

  void _showPokemonDetails(BuildContext context, dynamic pokemon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(pokemon['images']['large']),
                SizedBox(height: 16),
                Text('Name: ${pokemon['name']}'),
                SizedBox(height: 8),
                Text('Type: ${pokemon['types'].join(', ')}'),
                SizedBox(height: 8),
                Text('Rarity: ${pokemon['rarity']}'),
                SizedBox(height: 8),
                Text('Set: ${pokemon['set']['name']}'),
                SizedBox(height: 8),
                Text(
                  'Market Price: ${pokemon['tcgplayer']?['prices']?['holofoil']?['market'] ?? 'N/A'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                addToCart(pokemon); // Call the addToCart method
                Navigator.of(context).pop();
              },
              child: Text('Add to Cart'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class PokemonList extends StatefulWidget {
  final Function(dynamic) addToCart;
  final Function(BuildContext, dynamic) showDetails;

  PokemonList({required this.addToCart, required this.showDetails});

  @override
  _PokemonListState createState() => _PokemonListState();
}

class _PokemonListState extends State<PokemonList> {
  List<dynamic> pokemonData = [];

  @override
  void initState() {
    super.initState();
    fetchPokemonData();
  }

  Future<void> fetchPokemonData() async {
    final Uri url =
    Uri.parse('https://api.pokemontcg.io/v2/cards?q=name:gardevoir');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      if (responseData != null &&
          responseData is Map &&
          responseData.containsKey('data')) {
        setState(() {
          pokemonData = responseData['data'];
        });
      } else {
        throw Exception('Data format error');
      }
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return pokemonData.isEmpty
        ? Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: pokemonData.length,
      itemBuilder: (BuildContext context, int index) {
        final pokemon = pokemonData[index];
        final marketPrice =
            pokemon['tcgplayer']?['prices']?['holofoil']?['market'] ??
                'N/A';
        return Card(
          elevation: 4,
          margin: EdgeInsets.all(8),
          child: ListTile(
            onTap: () {
              widget.showDetails(context, pokemon);
            },
            leading: Image.network(pokemon['images']['small']),
            title: Text(pokemon['name']),
            subtitle: Text(
                'Market Price: ${marketPrice is String ? marketPrice : '\$${marketPrice.toStringAsFixed(2)}'}'),
          ),
        );
      },
    );
  }
}

class CartList extends StatelessWidget {
  final List<dynamic> cartItems;
  final Function(dynamic) removeCartItem;
  final Function(dynamic) addToCart; // Add this line

  CartList({required this.cartItems, required this.removeCartItem, required this.addToCart}); // Update this line

  @override
  Widget build(BuildContext context) {
    return cartItems.isEmpty
        ? Center(
      child: Text('Your cart is empty.'),
    )
        : ListView.builder(
      itemCount: cartItems.length,
      itemBuilder: (BuildContext context, int index) {
        final pokemon = cartItems[index];
        final marketPrice =
            pokemon['tcgplayer']?['prices']?['holofoil']?['market'] ??
                'N/A';
        return Card(
          elevation: 4,
          margin: EdgeInsets.all(8),
          child: ListTile(
            onTap: () {
              _showPokemonDetails(context, pokemon);
            },
            leading: Image.network(pokemon['images']['small']),
            title: Text(pokemon['name']),
            subtitle: Text(
                'Market Price: ${marketPrice is String ? marketPrice : '\$${marketPrice.toStringAsFixed(2)}'}'),
            trailing: IconButton(
              icon: Icon(Icons.remove_circle),
              onPressed: () {
                removeCartItem(pokemon);
              },
            ),
          ),
        );
      },
    );
  }

  void _showPokemonDetails(BuildContext context, dynamic pokemon) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.network(pokemon['images']['large']),
                SizedBox(height: 16),
                Text('Name: ${pokemon['name']}'),
                SizedBox(height: 8),
                Text('Type: ${pokemon['types'].join(', ')}'),
                SizedBox(height: 8),
                Text('Rarity: ${pokemon['rarity']}'),
                SizedBox(height: 8),
                Text('Set: ${pokemon['set']['name']}'),
                SizedBox(height: 8),
                Text(
                  'Market Price: ${pokemon['tcgplayer']?['prices']?['holofoil']?['market'] ?? 'N/A'}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                addToCart(pokemon); // Call the addToCart method
                Navigator.of(context).pop();
              },
              child: Text('Add to Cart'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class BuyNowDialog extends StatefulWidget {
  final double totalPrice;
  final Function(double) confirmPayment;

  BuyNowDialog({required this.totalPrice, required this.confirmPayment});

  @override
  _BuyNowDialogState createState() => _BuyNowDialogState();
}

class _BuyNowDialogState extends State<BuyNowDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cardNumberController;
  late TextEditingController _expiryDateController;
  late TextEditingController _cvvController;

  @override
  void initState() {
    super.initState();
    _cardNumberController = TextEditingController();
    _expiryDateController = TextEditingController();
    _cvvController = TextEditingController();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Confirm Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Total Amount: \$${widget.totalPrice.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildCreditCardForm(),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.confirmPayment(widget.totalPrice);
              // Display thank you message
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Thank You'),
                    content: Text('Payment Successful.'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('OK'),
                      ),
                    ],
                  );
                },
              );
            }
          },
          child: Text('Confirm Payment'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildCreditCardForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _cardNumberController,
            decoration: InputDecoration(
              labelText: 'Card Number',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your card number';
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _expiryDateController,
                  decoration: InputDecoration(
                    labelText: 'Expiry Date (MM/YY)',
                  ),
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter expiry date';
                    }
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _cvvController,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter CVV';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
