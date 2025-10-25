import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'messaging_person.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> with RouteAware {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> chats = [];
  bool isLoading = true;
  bool isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  /// Auto reload when coming back from another page
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures the page auto-refreshes when user comes back to it
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      await _loadChats();
      return true;
    });
  }

  Future<void> _loadChats() async {
    try {
      setState(() {
        if (!isRefreshing) isLoading = true;
      });

      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        debugPrint('No logged-in user.');
        return;
      }

      debugPrint('🔎 Current User ID: $currentUserId');

      final response = await supabase
          .from('messages')
          .select('''
          id,
          content,
          created_at,
          sender_id,
          receiver_id,
          pet_id,
          pets (
            id,
            name,
            image_url,
            owner_id
          ),
          profiles:receiver_id (
            id,
            full_name,
            image
          )
        ''')
          .or('sender_id.eq.$currentUserId,receiver_id.eq.$currentUserId')
          .order('created_at', ascending: false);

      debugPrint('📬 Messages fetched: ${response.length}');

      final Map<String, Map<String, dynamic>> conversationMap = {};

      for (final message in response) {
        final pet = message['pets'];
        if (pet == null) continue;

        final petId = pet['id'] ?? '';
        final senderId = message['sender_id'];
        final receiverId = message['receiver_id'];
        final otherUserId = senderId == currentUserId ? receiverId : senderId;

        final convoKey = '$petId-$otherUserId';
        if (conversationMap.containsKey(convoKey)) continue;

        // Fetch other user's profile
        final receiverProfile = await supabase
            .from('profiles')
            .select()
            .eq('id', otherUserId)
            .maybeSingle();

        final petName = pet['name'] ?? 'Unknown Pet';
        final petImage = pet['image_url'] ?? '';
        final ownerId = pet['owner_id'] ?? '';
        final receiverName = receiverProfile?['full_name'] ?? 'Unknown User';
        final receiverImage = receiverProfile?['image'] ?? '';

        conversationMap[convoKey] = {
          'petName': petName,
          'petImage': petImage,
          'petId': petId,
          'ownerId': ownerId,
          'receiverName': receiverName,
          'receiverImage': receiverImage,
          'lastMessage': message['content'],
          'created_at': message['created_at'],
        };
      }

      final sortedChats = conversationMap.values.toList()
        ..sort((a, b) => b['created_at'].compareTo(a['created_at']));

      debugPrint('✅ Unique chats built: ${sortedChats.length}');

      if (mounted) {
        setState(() {
          chats = sortedChats;
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e, stack) {
      debugPrint('❌ ERROR loading chats: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshChats() async {
    setState(() => isRefreshing = true);
    await _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload messages',
            onPressed: _isReloadingDisabled()
                ? null
                : () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshing messages...'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                    await _refreshChats();
                  },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshChats,
              color: Colors.brown,
              child: chats.isEmpty
                  ? ListView(
                      physics: AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 250),
                        Center(
                          child: Text(
                            'No conversations yet',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: chat['petImage'].isNotEmpty
                                ? NetworkImage(chat['petImage'])
                                : null,
                            child: chat['petImage'].isEmpty
                                ? const Icon(Icons.pets)
                                : null,
                          ),
                          title: Text(chat['petName']),
                          subtitle: Text(
                            chat['lastMessage'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: CircleAvatar(
                            radius: 16,
                            backgroundImage: chat['receiverImage'].isNotEmpty
                                ? NetworkImage(chat['receiverImage'])
                                : null,
                            child: chat['receiverImage'].isEmpty
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          ),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MessagingPerson(
                                  petName: chat['petName'],
                                  petImage: chat['petImage'],
                                  petId: chat['petId'],
                                  ownerId: chat['ownerId'],
                                ),
                              ),
                            );
                            // auto reload when returning from conversation
                            await _loadChats();
                          },
                        );
                      },
                    ),
            ),
    );
  }

  bool _isReloadingDisabled() => isLoading || isRefreshing;
}
