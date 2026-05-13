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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('AI Assistant'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
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

// ================= AI CHAT SCREEN =================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(ChatMessage(
      text: "Hello! I'm your AI assistant. I can help you with:\n"
          "• Currency conversion\n"
          "• Exchange rates\n"
          "• Financial advice\n"
          "• General questions\n\n"
          "How can I help you today?",
      isUser: false,
    ));
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    setState(() {
      _messages.add(ChatMessage(text: userMessage, isUser: true));
      _messageController.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      final aiResponse = await ApiService.getAIResponse(userMessage);
      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: "Sorry, I'm having trouble responding. Please try again.",
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(ChatMessage(
                  text: "Chat cleared! How can I help you?",
                  isUser: false,
                ));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index];
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.green,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

// Chat Message Widget
class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? Colors.green : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

// ================= API SERVICE =================

class ApiService {
  static const String _geminiApiKey = "AIzaSyD8dYk2j2D0fXhoOyGKn5jIu6De9TUHVvQY"; // Get from https://makersuite.google.com/app/apikey

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

  // AI CHATBOT API (Using Google Gemini)
  static Future<String> getAIResponse(String userMessage) async {
    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey'
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': userMessage}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        // Fallback to a free API if Gemini fails
        return await _getFallbackResponse(userMessage);
      }
    } catch (e) {
      // Fallback response
      return await _getFallbackResponse(userMessage);
    }
  }

  // Free fallback API (no API key required)
  static Future<String> _getFallbackResponse(String userMessage) async {
    try {
      // Using a free AI API (no key required)
      final url = Uri.parse('https://api.risup.ai/v1/chat/completions');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': userMessage}
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return _getLocalResponse(userMessage);
      }
    } catch (e) {
      return _getLocalResponse(userMessage);
    }
  }

  // Local intelligent responses
  static String _getLocalResponse(String userMessage) {
    String lowerMsg = userMessage.toLowerCase();

    if (lowerMsg.contains('hello') || lowerMsg.contains('hi')) {
      return "Hello! How can I help you with currency or financial questions today?";
    } else if (lowerMsg.contains('rate') || lowerMsg.contains('exchange')) {
      return "I can help you check exchange rates! Use the Currency Converter feature to get real-time rates for any currency.";
    } else if (lowerMsg.contains('convert')) {
      return "To convert currency, go to the Converter screen from the home page. Enter your USD amount and it will be converted to your local currency.";
    } else if (lowerMsg.contains('thank')) {
      return "You're welcome! Is there anything else I can help you with?";
    } else if (lowerMsg.contains('dollar') || lowerMsg.contains('usd')) {
      return "USD is the United States Dollar. You can convert it to your local currency using the Currency Converter feature.";
    } else {
      return "I'm here to help with currency conversion and financial questions. You can use the Currency Converter tool above, or ask me specific questions about exchange rates!";
    }
  }
}