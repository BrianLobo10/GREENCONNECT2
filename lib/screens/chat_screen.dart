import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/messages_provider.dart';
import '../services/firestore_service.dart';
import '../models/user.dart';

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  User? _otherUser;
  bool _isSendingImage = false;
  File? _selectedImage;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  int _previousMessageCount = 0;

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';

    // Cargar información del otro usuario
    _otherUser = await FirestoreService.instance.getUserById(widget.userId);
    
    // Cargar mensajes en TIEMPO REAL
    messagesProvider.loadMessagesStream(currentUserId, widget.userId);
    
    // Escuchar cambios en la cantidad de mensajes para hacer scroll
    messagesProvider.addListener(_onMessagesChanged);
    
    setState(() {});
    
    // Scroll al final (esperar un poco para que carguen los mensajes)
    Future.delayed(const Duration(milliseconds: 500), () {
      _scrollToBottom();
    });
  }

  void _onMessagesChanged() {
    final messagesProvider = context.read<MessagesProvider>();
    final currentCount = messagesProvider.messages.length;
    
    // Solo hacer scroll si hay nuevos mensajes
    if (currentCount > _previousMessageCount) {
      _scrollToBottom();
      _previousMessageCount = currentCount;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final messagesProvider = context.read<MessagesProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';

    await messagesProvider.sendMessage(
      currentUserId,
      widget.userId,
      _messageController.text.trim(),
    );

    _messageController.clear();

    // Scroll al final
    _scrollToBottom();
  }

  Future<void> _pickImage() async {
    try {
      // Seleccionar imagen de la galería
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _selectedImage = File(image.path);
      });
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _sendImageMessage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isSendingImage = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final messagesProvider = context.read<MessagesProvider>();
      final currentUserId = authProvider.currentUser?.id ?? '';

      // Enviar imagen
      await messagesProvider.sendMessageWithImage(
        currentUserId,
        widget.userId,
        _messageController.text.trim().isEmpty 
            ? '📷 Imagen' 
            : _messageController.text.trim(),
        _selectedImage!,
      );

      _messageController.clear();
      setState(() {
        _selectedImage = null;
        _isSendingImage = false;
      });

      // Scroll al final
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isSendingImage = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al enviar imagen: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _insertEmoji(String emoji) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  Future<void> _deleteMessage(String messageId, DateTime messageDate) async {
    final messagesProvider = context.read<MessagesProvider>();
    
    final canDelete = await messagesProvider.deleteMessage(messageId, messageDate);
    
    if (!mounted) return;
    
    if (canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mensaje eliminado'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No puedes eliminar mensajes después de 10 minutos'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    final messagesProvider = context.read<MessagesProvider>();
    messagesProvider.removeListener(_onMessagesChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showDeleteDialog(String messageId, DateTime messageDate) {
    final now = DateTime.now();
    final difference = now.difference(messageDate);
    final canDelete = difference.inMinutes <= 10;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          canDelete ? '¿Eliminar mensaje?' : 'No se puede eliminar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          canDelete
              ? 'Este mensaje se eliminará permanentemente.'
              : 'Solo puedes eliminar mensajes enviados hace menos de 10 minutos.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.poppins(color: AppColors.grey)),
          ),
          if (canDelete)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteMessage(messageId, messageDate);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Text('Eliminar', style: GoogleFonts.poppins(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final messagesProvider = context.watch<MessagesProvider>();
    final currentUserId = authProvider.currentUser?.id ?? '';

    if (_otherUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _otherUser!.foto ?? '👤',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _otherUser!.nombre,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${_otherUser!.edad} años',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            // Lista de mensajes
            Expanded(
              child: messagesProvider.messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 60,
                            color: AppColors.grey.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No hay mensajes aún',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '¡Envía el primer mensaje!',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messagesProvider.messages.length,
                      itemBuilder: (context, index) {
                        final message = messagesProvider.messages[index];
                        final isMe = message.emisorId == currentUserId;

                        return GestureDetector(
                          onLongPress: isMe && message.id != null
                              ? () => _showDeleteDialog(message.id!, message.fecha)
                              : null,
                          child: _buildMessageBubble(
                            message.texto,
                            isMe,
                            message.fecha,
                            message.imageUrl,
                          ),
                        );
                      },
                    ),
            ),

            // Preview de imagen seleccionada
            if (_selectedImage != null)
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Preview de la imagen
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_selectedImage!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Imagen seleccionada',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                          ),
                        ),
                        // Botón cancelar
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.error),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                        ),
                        // Botón enviar imagen
                        ElevatedButton.icon(
                          onPressed: _isSendingImage ? null : _sendImageMessage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          label: Text(
                            'Enviar',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Selector de emojis
            if (_showEmojiPicker)
              Container(
                height: 250,
                color: AppColors.background,
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _emojis.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        _insertEmoji(_emojis[index]);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _emojis[index],
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

            // Campo de texto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: _isSendingImage
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            SizedBox(width: 16),
                            Text('Enviando imagen...'),
                          ],
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        // Botón de emojis
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: _showEmojiPicker 
                                ? AppColors.primary.withOpacity(0.2)
                                : AppColors.secondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(22.5),
                          ),
                          child: IconButton(
                            icon: Icon(
                              _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                              color: AppColors.primary,
                              size: 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _showEmojiPicker = !_showEmojiPicker;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Botón de galería
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(22.5),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.image, color: AppColors.primary, size: 24),
                            onPressed: _pickImage,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Campo de texto
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                              controller: _messageController,
                              decoration: InputDecoration(
                                hintText: 'Escribe un mensaje...',
                                hintStyle: GoogleFonts.poppins(color: AppColors.grey),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              maxLines: null,
                              textCapitalization: TextCapitalization.sentences,
                              onTap: () {
                                if (_showEmojiPicker) {
                                  setState(() {
                                    _showEmojiPicker = false;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Botón de enviar
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white),
                            onPressed: _sendMessage,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Lista de emojis populares
  static const List<String> _emojis = [
    '😀', '😊', '😂', '🤣', '😍', '🥰', '😘', '😎',
    '😁', '😄', '😆', '🙂', '😉', '😌', '😇', '🥳',
    '😭', '😢', '😱', '😴', '🤔', '🤗', '🤭', '🤫',
    '👍', '👎', '👏', '🙌', '👋', '🤝', '💪', '🙏',
    '❤️', '💚', '💙', '💛', '💜', '🧡', '🖤', '💕',
    '🔥', '✨', '⭐', '🌟', '💯', '👌', '✌️', '🤞',
    '🎉', '🎊', '🎈', '🎁', '🏆', '🥇', '🎯', '💎',
  ];

  Widget _buildMessageBubble(String text, bool isMe, DateTime fecha, String? imageUrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(5),
                bottomRight: isMe ? const Radius.circular(5) : const Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mostrar imagen si existe
                if (imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 200,
                        height: 200,
                        color: Colors.grey[300],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  if (text.isNotEmpty && text != '📷 Imagen')
                    const SizedBox(height: 8),
                ],
                // Mostrar texto si no es solo "📷 Imagen"
                if (text.isNotEmpty && text != '📷 Imagen')
                  Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: isMe ? Colors.white : AppColors.black,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(fecha),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isMe ? Colors.white.withOpacity(0.8) : AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

