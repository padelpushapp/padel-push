import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({super.key});

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  LatLng? selectedPoint;

  static const LatLng defaultCenter = LatLng(39.4702, -0.3768); // Valencia centro

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seleccionar ubicación"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.4,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: defaultCenter,
              zoom: 13,
            ),
            onTap: (pos) {
              setState(() => selectedPoint = pos);
            },
            markers: selectedPoint == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId("chosen"),
                      position: selectedPoint!,
                    )
                  },
          ),

          // Confirm button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: selectedPoint == null
                  ? null
                  : () => Navigator.pop(context, selectedPoint),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text(
                "CONFIRMAR UBICACIÓN",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          )
        ],
      ),
    );
  }
}
