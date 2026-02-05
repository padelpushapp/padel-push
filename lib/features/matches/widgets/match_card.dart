import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/match_model.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.match,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat("dd/MM/yyyy").format(match.date);

    final timeFormatted = match.time.toString().substring(0, 5);

    Color playersColor;
    if (match.neededPlayers >= 3) {
      playersColor = Colors.redAccent;
    } else if (match.neededPlayers == 2) {
      playersColor = Colors.orangeAccent;
    } else {
      playersColor = Colors.green;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // CLUB
            Text(
              match.club ?? "Partido en club",
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            // FECHA + HORA
            Row(
              children: [
                _smallTag("${dateFormatted}"),
                const SizedBox(width: 8),
                _smallTag("$timeFormatted h"),
              ],
            ),

            const SizedBox(height: 16),

            // NIVEL + PRECIO
            Row(
              children: [
                _chip(
                  "${match.levelStart.toStringAsFixed(1)} - ${match.levelEnd.toStringAsFixed(1)}",
                  active: true,
                ),
                const SizedBox(width: 12),
                _chip("€ ${match.price.toStringAsFixed(2)}"),
              ],
            ),

            const SizedBox(height: 16),

            // ENTORNO + PARED + EXTRA
            Row(
              children: [
                _chip(match.environment ?? "Indoor"),
                const SizedBox(width: 12),
                _chip(match.wallType ?? "Cristal"),
                const SizedBox(width: 12),
                if (match.extraBalls) _chip("Bolas 🎾", active: true),
                if (match.extraBeer) ...[
                  const SizedBox(width: 12),
                  _chip("Cerveza 🍺", active: true)
                ],
              ],
            ),

            const SizedBox(height: 16),

            // JUGADORES FALTANTES
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: playersColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 18, color: playersColor),
                      const SizedBox(width: 6),
                      Text(
                        "Faltan ${match.neededPlayers}",
                        style: TextStyle(
                          color: playersColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _smallTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }
}
