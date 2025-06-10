import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matchmaker/features/auth/presentation/pages/login_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final inputDecoration = InputDecoration(
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          'Créer un compte',
                          style: GoogleFonts.pacifico(
                            fontSize: 32,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      TextField(
                        decoration: inputDecoration.copyWith(hintText: 'Pseudo'),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        decoration: inputDecoration.copyWith(hintText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        obscureText: true,
                        decoration:
                            inputDecoration.copyWith(hintText: 'Mot de passe'),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        obscureText: true,
                        decoration: inputDecoration.copyWith(
                            hintText: 'Confirmer le mot de passe'),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {},
                          child: Text(
                            "S'inscrire",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            text: 'Déjà un compte ? ',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: 'Se connecter.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
