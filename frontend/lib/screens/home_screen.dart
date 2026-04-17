import 'package:flutter/material.dart';
import 'package:frontend/screens/result_screen.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  final List<bool> _visibilityList = [];
  final List<String> _ingredients = [];
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(title: const Text('Buzdolabı AI Şefi')),
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const Text('🍳', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(
                'Ne pişirsem?',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Elindeki malzemeleri gir, sana tarif önerelim!',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Align(alignment: Alignment.centerLeft),
              const SizedBox(height: 8),
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: 'Malzeme ekle...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: AppTheme.primary),
                    onPressed: () {
                      if (_controller.text.isNotEmpty) {
                        setState(() {
                          _ingredients.add(_controller.text.trim());
                          _visibilityList.add(false);
                          _controller.clear();
                        });
                        Future.delayed(const Duration(milliseconds: 50), () {
                          setState(() {
                            _visibilityList[_visibilityList.length - 1] = true;
                          });
                        });
                      }
                    },
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    setState(() {
                      _ingredients.add(value.trim());
                      _visibilityList.add(false);
                      _controller.clear();
                    });
                    Future.delayed(const Duration(milliseconds: 50), () {
                      setState(() {
                        _visibilityList[_visibilityList.length - 1] = true;
                      });
                    });
                  }
                },
              ),
              if (_ingredients.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Henüz malzeme eklemedin 🥄',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_ingredients.length, (index) {
                  return AnimatedOpacity(
                    opacity: _visibilityList[index] ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      transform: Matrix4.translationValues(
                        0,
                        _visibilityList[index] ? 0 : 10,
                        0,
                      ),
                      child: Chip(
                        label: Text(_ingredients[index]),
                        backgroundColor: const Color(0xFFF0EDE8),
                        labelStyle: const TextStyle(color: Color(0xFF0F6E56)),
                        deleteIconColor: const Color(0xFF0F6E56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide.none,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        onDeleted: () {
                          setState(() {
                            _ingredients.removeAt(index);
                            _visibilityList.removeAt(index);
                          });
                        },
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
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
                                  ingredients: _ingredients,
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Tarif öner →'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
