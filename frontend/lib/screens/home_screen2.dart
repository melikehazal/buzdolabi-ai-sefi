import 'package:flutter/material.dart';
import 'package:frontend/screens/result_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme.dart';

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({super.key});

  @override
  State<HomeScreen2> createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {
  bool _isLoading = false;
  final List<String> _ingredients = [];
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Buzdolabı AI Şefi',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '🍳',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ne pişirsem?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Malzemelerini gir, AI şefin tarif önersin!',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Emoji kartları
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    _emojiCard('🥩', 'Et'),
                    const SizedBox(width: 12),
                    _emojiCard('🥦', 'Sebze'),
                    const SizedBox(width: 12),
                    _emojiCard('🧄', 'Baharat'),
                    const SizedBox(width: 12),
                    _emojiCard('🐟', 'Balık'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Malzeme ekleme
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Malzemeler',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            decoration: const InputDecoration(
                              hintText: 'Malzeme ekle...',
                            ),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                setState(() {
                                  _ingredients.add(value.trim());
                                  _controller.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (_controller.text.isNotEmpty) {
                              setState(() {
                                _ingredients.add(_controller.text.trim());
                                _controller.clear();
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ingredients
                          .map(
                            (ing) => Chip(
                              label: Text(ing),
                              backgroundColor: const Color(0xFFE1F5EE),
                              labelStyle: const TextStyle(
                                color: Color(0xFF0F6E56),
                              ),
                              deleteIconColor: const Color(0xFF0F6E56),
                              onDeleted: () {
                                setState(() {
                                  _ingredients.remove(ing);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading || _ingredients.isEmpty
                            ? null
                            : () async {
                                setState(() => _isLoading = true);
                                try {
                                  final response = await ApiService().getRecipe(
                                    _ingredients,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResultScreen(
                                        recipeResponse: response,
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  print('HATA: $e');
                                } finally {
                                  setState(() => _isLoading = false);
                                }
                              },
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text('Tarif öner →'),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emojiCard(String emoji, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _ingredients.add(label);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
