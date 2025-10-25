import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CommunityGuidelinesPage extends StatefulWidget {
  const CommunityGuidelinesPage({super.key});

  @override
  State<CommunityGuidelinesPage> createState() =>
      _CommunityGuidelinesPageState();
}

class _CommunityGuidelinesPageState extends State<CommunityGuidelinesPage> {
  bool _hasAgreed = false;
  bool _isLoading = true;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _loadAgreementStatus();
  }

  Future<void> _loadAgreementStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final agreed = prefs.getBool('userAgreedToStandards') ?? false;
    setState(() {
      _hasAgreed = agreed;
      _isLoading = false;
    });
  }

  Future<void> _saveAgreement() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('userAgreedToStandards', true);
    setState(() => _hasAgreed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8EDE4),
        body: Center(child: CircularProgressIndicator(color: Colors.brown)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8EDE4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8EDE4),
        elevation: 0,
        title: Text(
          "Community & Breeding Standards",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Our Commitment"),
            _sectionText(
              "FurMatch promotes responsible pet ownership, ethical breeding, "
              "and animal welfare. All users are expected to show compassion, respect, "
              "and care in every interaction — whether in breeding, adoption, or messaging."
            ),

            _sectionTitle("Responsible Breeding Standards"),
            _sectionText(
              "• Only breed healthy animals that are free from genetic disorders.\n"
              "• Ensure pets are of proper age and health before breeding.\n"
              "• Avoid overbreeding or breeding purely for profit.\n"
              "• Provide proper care, housing, and veterinary attention.\n"
              "• Never engage in illegal or unethical animal trade."
            ),

            _sectionTitle("Animal Welfare Act Compliance"),
            _sectionText(
              "FurMatch aligns with the Animal Welfare Act and local animal laws. "
              "Users must ensure that their practices are humane and legal:\n"
              "• Provide food, clean water, and shelter.\n"
              "• Regular veterinary check-ups.\n"
              "• Freedom from abuse or neglect.\n"
              "• Share pet health records when required."
            ),

            _sectionTitle("Community Conduct"),
            _sectionText(
              "All FurMatch users must:\n"
              "• Communicate respectfully with others.\n"
              "• Avoid false or misleading information.\n"
              "• Refrain from harassment, hate, or discrimination.\n"
              "• Report unethical or abusive activities promptly."
            ),

            _sectionTitle("User Compliance & Terms"),
            _sectionText(
              "By using FurMatch, you agree to:\n"
              "• Follow these standards and local laws.\n"
              "• Use the app ethically and responsibly.\n"
              "• Accept that violations may result in account suspension."
            ),

            _sectionTitle("Reporting Violations"),
            _sectionText(
              "If you see animal mistreatment or unethical breeding, report it:\n\n"
              "📧 petercesconde@su.edu.ph"
            ),

            const SizedBox(height: 30),
            if (!_hasAgreed) ...[
              Row(
                children: [
                  Checkbox(
                    value: _checked,
                    activeColor: Colors.brown,
                    onChanged: (value) {
                      setState(() => _checked = value ?? false);
                    },
                  ),
                  const Expanded(
                    child: Text(
                      "I have read and agree to follow these standards.",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _checked
                        ? Colors.brown.shade400
                        : Colors.brown.shade200,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.white),
                  label: const Text(
                    "Agree and Continue",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _checked
                      ? () async {
                          await _saveAgreement();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Thank you for agreeing to the community standards.",
                                ),
                                backgroundColor: Colors.brown,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      : null,
                ),
              ),
            ] else ...[
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown.shade400,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  label: const Text(
                    "Back to Settings",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],

            const SizedBox(height: 40),
            const Divider(thickness: 1),
            const SizedBox(height: 10),

            _sectionTitle("Additional Legal & Compliance"),

            _expandableSection(
              "Terms of Service",
              "By accessing or using FurMatch, you agree not to misuse our platform. "
              "You must not impersonate others, engage in fraudulent activity, "
              "or use FurMatch for illegal animal trade. Your account may be terminated "
              "for any breach of these conditions.",
            ),

            _expandableSection(
              "Privacy Policy",
              "FurMatch collects basic user data (email, pet info, photos) to provide "
              "a safe and personalized experience. We do not sell your data. "
              "You may request data deletion anytime by contacting petercesconde@su.edu.ph.",
            ),

            _expandableSection(
              "Data & Account Compliance",
              "All data is securely stored through Supabase and encrypted. "
              "Users are responsible for keeping their login credentials private. "
              "In cases of data misuse, account access may be restricted until resolved.",
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.jost(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.brown.shade700,
        ),
      ),
    );
  }

  Widget _sectionText(String text) {
    return Text(
      text,
      style: GoogleFonts.jost(
        fontSize: 15,
        height: 1.5,
        color: Colors.black87,
      ),
    );
  }

  Widget _expandableSection(String title, String content) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 8),
        childrenPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          title,
          style: GoogleFonts.jost(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.brown.shade600,
          ),
        ),
        iconColor: Colors.brown,
        collapsedIconColor: Colors.brown,
        children: [
          Text(
            content,
            style: GoogleFonts.jost(
              fontSize: 15,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
