import 'dart:io';
import 'dart:async';
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
import '../models/message.dart';
import '../widgets/user_avatar.dart';
import 'voice_call_screen.dart';
import 'video_call_screen.dart';
import '../services/call_notification_service.dart';

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
  bool _isSelectionMode = false;
  List<Message> _selectedMessages = [];
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Recargar mensajes cada 30 segundos como respaldo
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
    
    // Marcar mensajes como leídos cuando se abre el chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _markMessagesAsRead();
    });
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
    _refreshTimer?.cancel();
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
        title: _isSelectionMode 
            ? Text(
                '${_selectedMessages.length} seleccionado${_selectedMessages.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white),
              )
            : Row(
                children: [
                  UserAvatar(
                    photoUrl: _otherUser!.foto,
                    userName: _otherUser!.nombre,
                    radius: 20,
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
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _exitSelectionMode,
            ),
            IconButton(
              icon: const Icon(Icons.forward, color: Colors.white),
              onPressed: _selectedMessages.isNotEmpty ? _forwardSelectedMessages : null,
            ),
          ] else ...[
            // Botón de llamada de voz
            IconButton(
              onPressed: () => _startVoiceCall(),
              icon: const Icon(Icons.call, color: Colors.white),
              tooltip: 'Llamada de voz',
            ),
            // Botón de videollamada
            IconButton(
              onPressed: () => _startVideoCall(),
              icon: const Icon(Icons.videocam, color: Colors.white),
              tooltip: 'Videollamada',
            ),
            PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear_chat',
                  child: Row(
                    children: [
                      Icon(Icons.visibility_off, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Ocultar chat', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'clear_chat') {
                  _showClearChatDialog();
                }
              },
            ),
          ],
        ],
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
                          onLongPress: () {
                            if (!_isSelectionMode) {
                              _enterSelectionMode();
                              _toggleMessageSelection(message); // Seleccionar el mensaje que se mantuvo presionado
                            } else {
                              _toggleMessageSelection(message);
                            }
                          },
                          onTap: _isSelectionMode 
                              ? () => _toggleMessageSelection(message)
                              : (isMe && message.id != null
                                  ? () => _showDeleteDialog(message.id!, message.fecha)
                                  : null),
                          child: Stack(
                            children: [
                              Container(
                                decoration: _isSelectionMode && _selectedMessages.contains(message)
                                    ? BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      )
                                    : null,
                                child: _buildMessageBubble(
                                  message,
                                  isMe,
                                ),
                              ),
                              if (_isSelectionMode && _selectedMessages.contains(message))
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                            ],
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

  Widget _buildMessageBubble(Message message, bool isMe) {
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
                // Indicador de reenvío
                if (message.isForwarded) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withOpacity(0.2) : AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.forward,
                          size: 14,
                          color: isMe ? Colors.white70 : AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Reenviado de ${message.originalSenderName ?? 'Usuario'}',
                          style: GoogleFonts.poppins(
                            color: isMe ? Colors.white70 : AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Mostrar imagen si existe
                if (message.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: message.imageUrl!,
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
                  if (message.texto.isNotEmpty && message.texto != '📷 Imagen')
                    const SizedBox(height: 8),
                ],
                // Mostrar texto si no es solo "📷 Imagen"
                if (message.texto.isNotEmpty && message.texto != '📷 Imagen')
                  Text(
                    message.texto,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: isMe ? Colors.white : AppColors.black,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.fecha),
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isMe ? Colors.white.withOpacity(0.8) : AppColors.grey,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.leido ? Icons.done_all : Icons.done,
                        size: 12,
                        color: message.leido ? Colors.blue : Colors.white.withOpacity(0.8),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showForwardDialog(Message message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reenviar mensaje'),
          content: const Text('¿Quieres reenviar este mensaje a otro usuario?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/forward-message', extra: message);
              },
              child: const Text('Reenviar'),
            ),
          ],
        );
      },
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ocultar chat'),
          content: const Text('¿Estás seguro de que quieres ocultar todos los mensajes de esta conversación? Los mensajes se ocultarán solo para ti, el otro usuario podrá seguir viéndolos.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearChat();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Ocultar chat'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearChat() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.currentUser?.id;
      if (currentUserId == null) return;

      // Eliminar todos los mensajes de la conversación
      final messagesProvider = context.read<MessagesProvider>();
      await messagesProvider.clearChatMessages(currentUserId, widget.userId);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat oculto exitosamente'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al vaciar chat: $e')),
        );
      }
    }
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedMessages.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedMessages.clear();
    });
  }

  void _toggleMessageSelection(Message message) {
    setState(() {
      if (_selectedMessages.contains(message)) {
        _selectedMessages.remove(message);
      } else {
        _selectedMessages.add(message);
      }
    });
  }

  void _forwardSelectedMessages() {
    if (_selectedMessages.isEmpty) return;
    
    // Ordenar mensajes por fecha para mantener el orden
    _selectedMessages.sort((a, b) => a.fecha.compareTo(b.fecha));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reenviar ${_selectedMessages.length} mensaje${_selectedMessages.length > 1 ? 's' : ''}'),
        content: Text('¿Quieres reenviar estos mensajes a otro usuario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/forward-messages', extra: _selectedMessages);
            },
            child: const Text('Reenviar'),
          ),
        ],
      ),
    );
  }

  // Métodos para llamadas
  void _startVoiceCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Llamada de voz'),
        content: Text('¿Iniciar llamada de voz con ${_otherUser?.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateCall('voice');
            },
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  void _startVideoCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Videollamada'),
        content: Text('¿Iniciar videollamada con ${_otherUser?.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiateCall('video');
            },
            child: const Text('Llamar'),
          ),
        ],
      ),
    );
  }

  void _initiateCall(String callType) async {
    // Crear un canal único para la llamada
    final channelName = 'call_${widget.userId}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Enviar notificación de llamada
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    
    if (currentUser != null) {
      final callNotificationService = CallNotificationService();
      await callNotificationService.sendIncomingCallNotification(
        callerId: currentUser.id!,
        callerName: currentUser.nombre,
        receiverId: widget.userId,
        channelName: channelName,
        callType: callType,
      );
    }
    
    if (callType == 'voice') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoiceCallScreen(
            channelName: channelName,
            otherUserName: _otherUser?.nombre ?? 'Usuario',
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(
            channelName: channelName,
            otherUserName: _otherUser?.nombre ?? 'Usuario',
          ),
        ),
      );
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final currentUserId = authProvider.currentUser?.id;
      
      if (currentUserId != null) {
        await FirestoreService.instance.markMessagesAsRead(currentUserId, widget.userId);
      }
    } catch (e) {
      debugPrint('Error marcando mensajes como leídos: $e');
    }
  }
}

