// lib/features/matches/widgets/location_autocomplete_field.dart
import 'package:flutter/material.dart';
import '../../../data/clubs_valencia.dart'; // lista local de clubs

/// Campo de búsqueda simple que usa la lista local `valenciaClubs`.
/// Llama a onLocationSelected(name, lat, lng) cuando el usuario selecciona una sugerencia.
/// Llama a onManualTextChanged(text) cuando el usuario escribe (para mantener el texto del campo).
class LocationAutocompleteField extends StatefulWidget {
  final void Function(String name, double lat, double lng) onLocationSelected;
  final void Function(String text)? onManualTextChanged;

  const LocationAutocompleteField({super.key, required this.onLocationSelected, this.onManualTextChanged});

  @override
  State<LocationAutocompleteField> createState() => _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final TextEditingController _ctrl = TextEditingController();
  List<ClubData> suggestions = [];
  bool loading = false;

  void _onChanged(String text) {
    widget.onManualTextChanged?.call(text);

    // búsqueda local sencilla (nombre o dirección contiene texto)
    final q = text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        suggestions = [];
      });
      return;
    }

    setState(() {
      // pequeña debounce simulada: no real debounce here but instant filtering
      suggestions = valenciaClubs.where((c) {
        final name = c.name.toLowerCase();
        final address = c.address.toLowerCase();
        return name.contains(q) || address.contains(q);
      }).toList();
    });
  }

  void _selectClub(ClubData c) {
    _ctrl.text = c.name;
    setState(() {
      suggestions = [];
    });
    widget.onLocationSelected(c.name, c.lat, c.lng);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _ctrl,
          decoration: InputDecoration(
            hintText: "Buscar club o dirección (lista local)",
            filled: true,
            fillColor: const Color(0xFFF2F3F5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            suffixIcon: _ctrl.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _ctrl.clear();
                      _onChanged('');
                    },
                  )
                : null,
          ),
          onChanged: _onChanged,
        ),

        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
            ),
            child: Column(
              children: suggestions.map((c) {
                return ListTile(
                  dense: true,
                  title: Text(c.name),
                  subtitle: Text(c.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => _selectClub(c),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
