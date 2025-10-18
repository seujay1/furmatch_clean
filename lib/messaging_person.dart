import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:furmatch_clean/services/supabase_service.dart';

class MessagingPerson extends StatefulWidget {
  final String petName;
  final String petImage;
  final String petId;
  final String ownerId;

  const MessagingPerson({
    super.key,
    required this.petName,
    required this.petImage,
    required this.petId,
    required this.ownerId,
  });

  @override
  State<MessagingPerson> createState() => _MessagingPersonState();
}

class _MessagingPersonState extends State<MessagingPerson> {
  final SupabaseClient client = SupabaseService.client;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  String? currentUserId;
  String chatPartnerId = '';
  String chatPartnerName = 'User';
  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
    super.dispose();
  }

  Future<void> _initChat() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    currentUserId = user.id;

    // ------------------------
    chatPartnerId = widget.ownerId;

    await _loadChatPartnerName();
    await _loadInitialMessages();
    _setupMessageStream();
  }

  Future<void> _loadChatPartnerName() async {
    if (chatPartnerId.isEmpty) return;
    try {
      final resp = await client
          .from('profiles')
          .select('full_name')
          .eq('id', chatPartnerId)
          .maybeSingle();
      if (resp != null &&
          resp['full_name'] != null &&
          resp['full_name'].toString().isNotEmpty) {
        chatPartnerName = resp['full_name'];
      }
    } catch (_) {
      chatPartnerName = 'User';
    }
  }

  Future<void> _loadInitialMessages() async {
    try {
      final response = await client
          .from('messages')
          .select()
          .eq('pet_id', widget.petId)
          .order('created_at', ascending: true);

      final allMessages =
          (response as List).map((e) => Map<String, dynamic>.from(e)).toList();

      final visible = allMessages.where((msg) {
        final sender = msg['sender_id'];
        final receiver = msg['receiver_id'];
        return (sender == currentUserId || receiver == currentUserId);
      }).toList();

      visible.sort(_compareByCreatedAt);

      if (mounted) {
        setState(() => _messages = visible);
        _scrollToBottom();
      }
    } catch (e) {
      print('initial load FAILED: $e');
    }
  }

  void _setupMessageStream() {
    if (currentUserId == null) return;

    _subscription?.cancel();

    // show only messages for this pet
    final stream = client
        .from('messages:pet_id=eq.${widget.petId}')
        .stream(primaryKey: ['id']);

    _subscription = stream.listen((messages) {
      try {
        final visibleMessages = messages.where((msg) {
          final sender = msg['sender_id'];
          final receiver = msg['receiver_id'];
          return sender == currentUserId || receiver == currentUserId;
        }).toList();

        // no duplicates by id
        final existingIds = _messages.map((m) => m['id']).toSet();
        for (var msg in visibleMessages) {
          if (!existingIds.contains(msg['id'])) {
            _messages.add(msg);
          }
        }

        _messages.sort(_compareByCreatedAt);

        if (mounted) {
          setState(() {});
          _scrollToBottom();
        }
      } catch (e) {
        print('realtime processing ERROR: $e');
      }
    }, onError: (err) {
      print('realtime stream ERROR: $err');
    });
  }

  int _compareByCreatedAt(Map<String, dynamic> a, Map<String, dynamic> b) {
    DateTime parseCreated(dynamic v) {
      if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0);
    }

    return parseCreated(a['created_at'])
        .compareTo(parseCreated(b['created_at']));
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || currentUserId == null || chatPartnerId.isEmpty) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMessage = {
      'id': tempId,
      'sender_id': currentUserId,
      'receiver_id': chatPartnerId,
      'pet_id': widget.petId,
      'content': text,
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() => _messages.add(tempMessage));
    _controller.clear();
    _scrollToBottom();

    try {
      final inserted = await client
          .from('messages')
          .insert({
            'sender_id': currentUserId,
            'receiver_id': chatPartnerId,
            'pet_id': widget.petId,
            'content': text,
          })
          .select()
          .maybeSingle();

      if (!mounted || inserted == null) return;

      final idx = _messages.indexWhere((m) => m['id'] == tempId);
      if (idx != -1) setState(() => _messages[idx] = inserted);

      _scrollToBottom();
    } catch (e) {
      print('ERROR sending message: $e');
      if (mounted)
        setState(() => _messages.removeWhere((m) => m['id'] == tempId));
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('FAILED to send message.')));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 60,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(String? ts) {
    if (ts == null) return '';
    final dt = DateTime.tryParse(ts);
    if (dt == null) return '';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.petImage.startsWith('http')
                  ? NetworkImage(widget.petImage)
                  : const AssetImage('assets/Logos/MAINPAGE.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                widget.petName,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.brown[300],
      ),
      backgroundColor: const Color(0xFFF8F4EF),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('No messages yet.'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['sender_id'] == currentUserId;
                      final senderName = isUser ? 'You' : chatPartnerName;
                      final receiverName = isUser ? chatPartnerName : 'You';
                      final timestamp = _formatTimestamp(msg['created_at']);

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 14),
                          decoration: BoxDecoration(
                            color:
                                isUser ? Colors.brown[300] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$senderName → $receiverName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                msg['content'] ?? '',
                                style: TextStyle(
                                  color: isUser ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timestamp,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Type a message...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.brown),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
