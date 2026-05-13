import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Currency App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

// ================= HOME SCREEN =================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String countryName = '';
  String currencyCode = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCountryData();
  }

  Future<void> loadCountryData() async {
    try {
      final data = await ApiService.getCountryData();

      setState(() {
        countryName = data['country_name'];
        currencyCode = data['currency'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        countryName = 'Pakistan';
        currencyCode = 'PKR';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Country Info')),
      body: Center(
        child: isLoading
            ? const CircularProgressIndicator()
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Country: $countryName',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 20),
              Text(
                'Currency: $currencyCode',
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CurrencyScreen(currencyCode: currencyCode),
                    ),
                  );
                },
                child: const Text('Open Converter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= CURRENCY SCREEN =================

class CurrencyScreen extends StatefulWidget {
  final String currencyCode;

  const CurrencyScreen({super.key, required this.currencyCode});

  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final TextEditingController amountController = TextEditingController();

  double result = 0;
  bool isLoading = false;

  Future<void> convertCurrency() async {
    if (amountController.text.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final rate =
      await ApiService.getExchangeRate(widget.currencyCode);

      final amount = double.parse(amountController.text);

      setState(() {
        result = amount * rate;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        result = 0;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currency Converter')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Convert USD → ${widget.currencyCode}',
              style: const TextStyle(fontSize: 22),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Enter USD Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: convertCurrency,
              child: const Text('Convert'),
            ),
            const SizedBox(height: 30),
            isLoading
                ? const CircularProgressIndicator()
                : Text(
              'Result: ${result.toStringAsFixed(2)} ${widget.currencyCode}',
              style: const TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= API SERVICE =================

class ApiService {
  // 🔥 FIXED + RELIABLE API
  static Future<Map<String, dynamic>> getCountryData() async {
    final response =
    await http.get(Uri.parse('https://ipapi.co/json/'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return {
        'country_name': data['country_name'] ?? 'Pakistan',
        'currency': data['currency'] ?? 'PKR',
      };
    } else {
      throw Exception('Country API failed');
    }
  }

  // SAFE EXCHANGE API
  static Future<double> getExchangeRate(String currencyCode) async {
    final response =
    await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final rate = data['rates'][currencyCode];

      if (rate == null) {
        throw Exception('Currency not supported');
      }

      return (rate as num).toDouble();
    } else {
      throw Exception('Exchange API failed');
    }
  }
}