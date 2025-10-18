import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  final List<Map<String, String>> faqs = const [
    {
      "question": "How to add a pet?",
      "answer": "Go to the home page and tap '+'."
    },
    {
      "question": "How to edit profile?",
      "answer": "Go to Settings → Profile or tap your avatar."
    },
    {
      "question": "How to delete a pet?",
      "answer": "Tap on a pet and select delete."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8EDE4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EDE4),
        elevation: 0,
        title:
            Text("Help Center", style: GoogleFonts.jost(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: faqs.length,
        itemBuilder: (context, index) {
          final faq = faqs[index];
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExpansionTile(
              title: Text(faq['question']!,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(faq['answer']!),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
