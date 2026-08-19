/// Brevo (formerly Sendinblue) configuration.
/// Sign up FREE at https://www.brevo.com/ — 300 emails/day, no credit card.
///
/// How to get your API key (all free):
///   1. Go to https://www.brevo.com/ → Sign Up (use your Gmail)
///   2. Go to Account → SMTP & API → API Keys tab
///   3. Click "Generate a new API key" → copy it here
///   4. Set your sender name and the email you registered with
class EmailConfig {
  // ✅ Configured automatically via Brevo free account
  static const String apiKey = String.fromEnvironment('BREVO_API_KEY', defaultValue: '');

  /// The email address registered with on Brevo (used as sender).
  static const String senderEmail = 'msaketh582@gmail.com';
  static const String senderName  = 'PetConnect';

  static const String apiUrl =
      'https://api.brevo.com/v3/transactionalEmails/send';
}
