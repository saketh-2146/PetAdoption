import 'dart:convert';
import 'package:http/http.dart' as http;
import 'email_config.dart';

/// Sends transactional emails via the Brevo REST API.
/// Free tier: 300 emails/day — no credit card, no domain verification needed.
/// Sign up at https://www.brevo.com/
class EmailService {
  /// Sends an adoption request email to the seller.
  static Future<void> sendAdoptionEmail({
    required String sellerEmail,
    required String petName,
    required String applicantName,
    required String applicantEmail,
    required String applicantPhone,
    required String applicantAddress,
    required String note,
  }) async {
    final response = await http.post(
      Uri.parse(EmailConfig.apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'api-key': EmailConfig.apiKey,
      },
      body: jsonEncode({
        'sender': {
          'name': EmailConfig.senderName,
          'email': EmailConfig.senderEmail,
        },
        'to': [
          {'email': sellerEmail},
        ],
        'subject': '🎉 New Adoption Request for $petName!',
        'textContent': '''
You have a new adoption request for $petName on PetConnect!

─────────────────────────────
 Applicant Details
─────────────────────────────
Name    : $applicantName
Email   : $applicantEmail
Phone   : $applicantPhone
Address : $applicantAddress

Message :
${note.isEmpty ? 'No message provided.' : note}
─────────────────────────────

Please reach out to the applicant to arrange the adoption.

— PetConnect Team
''',
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Brevo email error ${response.statusCode}: ${response.body}');
    }
  }
}

