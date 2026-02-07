import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> {
  final StorageService _storageService = StorageService();
  final TextEditingController _apiKeyController = TextEditingController();
  
  bool _isLoading = true;
  String _selectedProvider = 'openai';

  final Map<String, String> _providers = {
    'openai': 'OpenAI (ChatGPT)',
    'gemini': 'Google Gemini',
    'anthropic': 'Anthropic (Claude)',
    'ollama': 'Ollama (Local)',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    final provider = await _storageService.getAiProvider() ?? 'openai';
    String? key;

    switch (provider) {
      case 'openai':
        key = await _storageService.getOpenAiApiKey();
        break;
      case 'gemini':
        key = await _storageService.getGeminiApiKey();
        break;
      case 'anthropic':
        key = await _storageService.getAnthropicApiKey();
        break;
      case 'ollama':
        key = await _storageService.getOllamaUrl();
        break;
    }

    if (mounted) {
      setState(() {
        _selectedProvider = provider;
        _apiKeyController.text = key ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _onProviderChanged(String? newValue) async {
    if (newValue == null) return;

    // Save current input before switching (optional UX choice, keeping it simple for now)
    // Actually, let's load the saved key for the new provider so the user doesn't lose data
    
    setState(() => _selectedProvider = newValue);
    
    String? key;
    switch (newValue) {
      case 'openai':
        key = await _storageService.getOpenAiApiKey();
        break;
      case 'gemini':
        key = await _storageService.getGeminiApiKey();
        break;
      case 'anthropic':
        key = await _storageService.getAnthropicApiKey();
        break;
      case 'ollama':
        key = await _storageService.getOllamaUrl();
        break;
    }
    
    if (mounted) {
      setState(() {
        _apiKeyController.text = key ?? '';
      });
    }
  }

  Future<void> _saveSettings() async {
    await _storageService.saveAiProvider(_selectedProvider);
    
    final value = _apiKeyController.text.trim();
    switch (_selectedProvider) {
      case 'openai':
        await _storageService.saveOpenAiApiKey(value);
        break;
      case 'gemini':
        await _storageService.saveGeminiApiKey(value);
        break;
      case 'anthropic':
        await _storageService.saveAnthropicApiKey(value);
        break;
      case 'ollama':
        await _storageService.saveOllamaUrl(value);
        break;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Features'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.purple))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select AI Provider',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282828),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProvider,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF282828),
                        style: const TextStyle(color: Colors.white),
                        icon: const Icon(Icons.arrow_drop_down, color: Colors.purple),
                        items: _providers.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value),
                          );
                        }).toList(),
                        onChanged: _onProviderChanged,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _selectedProvider == 'ollama' ? 'Server URL' : 'API Key',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiKeyController,
                    style: const TextStyle(color: Colors.white),
                    obscureText: _selectedProvider != 'ollama', // Show URL visible
                    decoration: InputDecoration(
                      hintText: _getHintText(),
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      filled: true,
                      fillColor: const Color(0xFF282828),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveSettings,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Settings', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getHintText() {
    switch (_selectedProvider) {
      case 'openai':
        return 'sk-...';
      case 'gemini':
        return 'AI...';
      case 'anthropic':
        return 'sk-ant-...';
      case 'ollama':
        return 'http://localhost:11434';
      default:
        return '';
    }
  }
}
