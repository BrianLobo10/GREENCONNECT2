import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import 'user_avatar.dart';

class MentionAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final int maxLines;
  final Function(String) onTextChanged;

  const MentionAutocomplete({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLines = 5,
    required this.onTextChanged,
  });

  @override
  State<MentionAutocomplete> createState() => _MentionAutocompleteState();
}

class _MentionAutocompleteState extends State<MentionAutocomplete> {
  final FirestoreService _firestoreService = FirestoreService.instance;
  List<User> _suggestedUsers = [];
  bool _isLoading = false;
  String _currentQuery = '';
  int _cursorPosition = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    
    setState(() {
      _cursorPosition = cursorPos;
    });

    // Buscar menciones en el texto
    final RegExp mentionRegex = RegExp(r'@(\w*)$');
    final match = mentionRegex.firstMatch(text.substring(0, cursorPos));
    
    if (match != null) {
      final query = match.group(1) ?? '';
      if (query != _currentQuery) {
        _currentQuery = query;
        _searchUsers(query);
      }
    } else {
      setState(() {
        _suggestedUsers = [];
        _currentQuery = '';
      });
    }

    widget.onTextChanged(text);
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        _suggestedUsers = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final users = await _firestoreService.searchUsers(query);
      setState(() {
        _suggestedUsers = users.take(5).toList(); // Limitar a 5 sugerencias
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _suggestedUsers = [];
        _isLoading = false;
      });
    }
  }

  void _selectUser(User user) {
    final text = widget.controller.text;
    final cursorPos = widget.controller.selection.baseOffset;
    
    // Encontrar la posición del @
    final atIndex = text.lastIndexOf('@', cursorPos - 1);
    if (atIndex != -1) {
      final beforeAt = text.substring(0, atIndex);
      final afterCursor = text.substring(cursorPos);
      final newText = '$beforeAt@${user.nombre} $afterCursor';
      
      widget.controller.text = newText;
      widget.controller.selection = TextSelection.collapsed(
        offset: atIndex + user.nombre.length + 2,
      );
    }

    setState(() {
      _suggestedUsers = [];
      _currentQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Escribe algo...',
            hintStyle: GoogleFonts.poppins(
              color: Colors.grey[500],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: GoogleFonts.poppins(),
        ),
        
        // Lista de sugerencias
        if (_suggestedUsers.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: _suggestedUsers.map((user) {
                return ListTile(
                  leading: UserAvatar(
                    photoUrl: user.foto,
                    userName: user.nombre,
                    radius: 20,
                  ),
                  title: Text(
                    user.nombre,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '@${user.nombre.toLowerCase().replaceAll(' ', '')}',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  onTap: () => _selectUser(user),
                );
              }).toList(),
            ),
          ),
        
        if (_isLoading)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Buscando usuarios...',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
