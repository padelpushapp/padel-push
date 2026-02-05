// lib/features/utils/notification_overlay.dart
import 'package:flutter/material.dart';
import 'notification_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/match_service.dart';

class NotificationOverlay extends StatelessWidget {
  const NotificationOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>?>(
      valueListenable: NotificationState.data,
      builder: (context, data, _) {
        if (data == null) return const SizedBox.shrink();

        final title = data['title'] ?? 'Plaza disponible';
        final body = data['body'] ?? '';
        final matchId = data['match_id'];
        final waitingId = data['waiting_id'];

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
                  Text(title,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  Text(body, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: NotificationState.clear,
                          child: const Text('RECHAZAR'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            NotificationState.clear();
                            final userId = Supabase
                                .instance.client.auth.currentUser?.id;
                            if (userId == null) return;

                            await MatchService().acceptSlotViaFunction(
                              matchId: matchId,
                              userId: userId,
                              waitingId: waitingId,
                            );
                          },
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
      },
    );
  }
}
