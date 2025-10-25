import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterPage extends StatefulWidget {
  const HelpCenterPage({super.key});

  @override
  State<HelpCenterPage> createState() => _HelpCenterPageState();
}

class _HelpCenterPageState extends State<HelpCenterPage> {
  final List<Map<String, String>> faqs = const [
    {
      "question": "How do I add a pet?",
      "answer": "Go to the Home page and tap the '+' button. Fill out your pet’s details such as name, breed, and age, then tap Save."
    },
    {
      "question": "How can I edit or update my pet’s profile?",
      "answer": "Open the pet profile you want to edit in your home page, then tap the 'Edit' icon or menu option to update your pet’s information."
    },
    {
      "question": "How do I delete a pet?",
      "answer": "Go to your pet’s profile, tap the trash button at the top and select 'Delete Pet'. Confirm when prompted."
    },
    {
      "question": "How do I edit my personal profile?",
      "answer": "Go to Settings → Profile, or tap your avatar on the navigation bar to update your name, address, or profile picture."
    },
    {
      "question": "I forgot my password. How can I reset it?",
      "answer": "On the login screen, tap 'Forgot Password?'. You will be prompted to email our support team."
    },
    {
      "question": "Why can’t I log in?",
      "answer": "Make sure your email is verified and your internet connection is stable. If the issue continues, just email our support team"
    },
    {
      "question": "How do I verify my email?",
      "answer": "When you register, you’ll receive an email verification link. Tap the link to confirm your account before logging in."
    },
    {
      "question": "How do I start chatting with other users?",
      "answer": "Go to your 'Pets' in navigation bar and you'll see the pet profiles and tap the 'Message Owner' button to start a conversation with the pet’s owner."
    },
    {
      "question": "How can I report or block a user?",
      "answer": "Simply send us a feedback in 'Send Feedback'."
    },
    {
      "question": "The app is not loading properly. What should I do?",
      "answer": "Try closing and reopening the app. If the issue continues, check your internet connection or reinstall the app."
    },
    {
      "question": "How can I delete my account?",
      "answer": "Go to Settings → Delete Account. This will permanently remove your data from the app."
    },
    {
      "question": "Who can I contact for support?",
      "answer": "You can email us at petercesconde@su.edu.ph"
    },
  ];

  List<Map<String, String>> filteredFaqs = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredFaqs = faqs; // show all by default
    _searchController.addListener(_filterFaqs);
  }

  void _filterFaqs() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredFaqs = faqs
          .where((faq) =>
              faq['question']!.toLowerCase().contains(query) ||
              faq['answer']!.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDE4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EDE4),
        elevation: 0,
        title: Text(
          "Help Center",
          style: GoogleFonts.jost(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
// --------------------search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search help topics...",
                prefixIcon: const Icon(Icons.search, color: Colors.brown),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

// ---------------------FAQs list
          Expanded(
            child: filteredFaqs.isEmpty
                ? const Center(
                    child: Text(
                      "No results found.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = filteredFaqs[index];
                      return Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ExpansionTile(
                          iconColor: Colors.black54,
                          collapsedIconColor: Colors.black45,
                          title: Text(
                            faq['question']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                faq['answer']!,
                                style: const TextStyle(fontSize: 15, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
