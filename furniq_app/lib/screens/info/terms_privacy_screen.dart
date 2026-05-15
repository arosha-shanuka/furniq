import 'package:flutter/material.dart';

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Privacy')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Welcome to Furniq. By using our services, you agree to these terms. '
              'Please read them carefully.\n\n'
              '1. Use of Services\n'
              'You must follow any policies made available to you within the services.\n\n'
              '2. Your Account\n'
              'You are responsible for maintaining the security of your account.\n\n'
              '3. Privacy\n'
              'Our privacy policies explain how we treat your personal data and protect your privacy when you use our services.\n\n'
              '4. Content\n'
              'Our services display some content that is not Furniq\'s. This content is the sole responsibility of the entity that makes it available.',
            ),
            SizedBox(height: 32),
            Text(
              'Privacy Policy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              'Your privacy is important to us. This privacy policy explains what personal data Furniq collects from you and how we use it.\n\n'
              '1. Information Collection\n'
              'We collect information to provide better services to our users.\n\n'
              '2. How We Use Information\n'
              'We use the information collected to provide, maintain, protect and improve our services.\n\n'
              '3. Information Sharing\n'
              'We do not share personal information with companies, organizations, or individuals outside of Furniq except in certain cases.\n\n'
              '4. Data Security\n'
              'We work hard to protect Furniq and our users from unauthorized access or unauthorized alteration, disclosure, or destruction of information.',
            ),
          ],
        ),
      ),
    );
  }
}
