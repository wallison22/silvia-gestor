import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/photo_service.dart';

/// Foto de uma peça. Sem [width], ocupa a largura disponível.
class PieceThumb extends StatelessWidget {
  const PieceThumb(this.photoName, {this.width, this.height = 48, super.key});

  final String? photoName;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final File? file = PhotoService.file(photoName);
    final double w = width ?? double.infinity;
    final Widget fallback = Container(
      width: w,
      height: height,
      color: const Color(0xFFF1F5F9),
      child: const Icon(Icons.image_not_supported_outlined,
          color: Color(0xFF94A3B8)),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(13),
      child: file == null
          ? fallback
          : Image.file(
              file,
              width: w,
              height: height,
              fit: BoxFit.cover,
              cacheWidth: width == null ? 1080 : 240,
              errorBuilder: (_, __, ___) => fallback,
            ),
    );
  }
}

/// Campo opcional para escolher a foto da peça.
class PhotoField extends StatelessWidget {
  const PhotoField({
    required this.photoName,
    required this.onChanged,
    super.key,
  });

  final String? photoName;
  final ValueChanged<String?> onChanged;

  Future<void> _pick(BuildContext context, bool camera) async {
    try {
      final String? name = await PhotoService.pick(camera: camera);
      if (name != null && context.mounted) onChanged(name);
    } catch (e) {
      debugPrint('Falha ao obter foto: $e');
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          content: const Text('Não foi possível abrir a câmera ou a galeria.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PhotoService.available) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: <Widget>[
          if (photoName != null) ...<Widget>[
            PieceThumb(photoName, width: 64, height: 64),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Wrap(
              children: <Widget>[
                TextButton.icon(
                  onPressed: () => _pick(context, true),
                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                  label: const Text('Tirar foto'),
                ),
                TextButton.icon(
                  onPressed: () => _pick(context, false),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galeria'),
                ),
                if (photoName != null)
                  TextButton.icon(
                    onPressed: () => onChanged(null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Remover foto'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
