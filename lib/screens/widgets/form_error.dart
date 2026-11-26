import 'package:flutter/material.dart';

/// Erro exibido dentro do formulario. (SnackBar fica escondido atras do
/// bottom sheet.)
class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        message!,
        style: const TextStyle(
            fontSize: 13,
            color: Color(0xFFB91C1C),
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
