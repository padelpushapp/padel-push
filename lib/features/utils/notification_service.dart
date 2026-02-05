import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/match_service.dart';

class NotificationService {
  static OverlayEntry? _entry;

  // ============================================================
  // ✅ MOSTRAR POPUP GLOBAL (ENCIMA DE MAPS Y TODO)
  // ============================================================

  static void show(BuildContext context, Map<String, dynamic> data) {
    if (_entry != null) return; // evita duplicados

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (_) => _NotificationPopup(
        data: data,
        onClose: _remove,
      ),
    );

    overlay.insert(_entry!);
  }

  static void _remove() {
    _entry?.remove();
    _entry = null;
  }
}

// ============================================================
// 🎨 POPUP UI / UX
// ============================================================

class _NotificationPopup extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onClose;

  const _NotificationPopup({
    required this.data,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final matchId = data['match_id'];
    final waitingId = data['waiting_id'];
    final title = data['title'] ?? 'Plaza disponible';
    final body = data['body'] ?? 'Se ha liberado una plaza';

    return Material(
      color: Colors.black.withOpacity(0.35),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // ============================
              // BOTONES
              // ============================

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        onClose();
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('RECHAZAR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        onClose();

                        final userId =
                            Supabase.instance.client.auth.currentUser?.id;
                        if (userId == null) return;

                        if (matchId == null || waitingId == null) return;

                        final service = MatchService();
                        await service.acceptSlotViaFunction(
                          matchId: matchId.toString(),
                          userId: userId,
                          waitingId: waitingId.toString(),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('ACEPTAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
