import 'package:flutter/material.dart';

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  final Animation<double> animation;

  const _BottomBar({
    required this.index,
    required this.onTap,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Stack(
        children: [
          BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _item(Icons.map, 0),
                _item(Icons.event, 1),
                const SizedBox(width: 48), // hueco FAB
                _item(Icons.emoji_events, 2),
                _item(Icons.person, 3),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: MediaQuery.of(context).size.width *
                (index / 4) +
                12,
            child: FadeTransition(
              opacity: animation,
              child: Container(
                width: 32,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, int i) {
    final active = i == index;
    return IconButton(
      onPressed: () => onTap(i),
      icon: Icon(
        icon,
        color: active ? Colors.black : Colors.grey,
        size: active ? 26 : 24,
      ),
    );
  }
}
