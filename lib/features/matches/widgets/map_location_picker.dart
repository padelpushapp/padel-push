// lib/features/widgets/map_location_picker.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapLocationPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const MapLocationPicker({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<MapLocationPicker> createState() => _MapLocationPickerState();
}

class _MapLocationPickerState extends State<MapLocationPicker> {
  GoogleMapController? _controller;
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _picked = LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initPos = CameraPosition(target: LatLng(widget.initialLat, widget.initialLng), zoom: 16);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajustar ubicación"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              if (_picked != null) Navigator.pop(context, _picked);
            },
            child: const Text("OK", style: TextStyle(color: Colors.black)),
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: initPos,
            onMapCreated: (c) => _controller = c,
            onTap: (pos) => setState(() => _picked = pos),
            markers: _picked == null
                ? {}
                : {
                    Marker(markerId: const MarkerId("picked"), position: _picked!),
                  },
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Center(
            child: IgnorePointer(
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, size: 28, color: Colors.red),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: () {
                if (_picked != null) Navigator.pop(context, _picked);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text("Usar posición", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
