import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static const String apiKey = "AIzaSyDZBS_bZKMKB9Zw3HYOYQpawFdOQQYdLcM";

  /// Places API (New) → búsqueda por texto
  static Future<List<Map<String, String>>> autocomplete(String input) async {
    final url = Uri.parse(
      "https://places.googleapis.com/v1/places:searchText",
    );

    final body = {
      "textQuery": input,
      "pageSize": 5,
      "languageCode": "es",
      "regionCode": "ES",
    };

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
        "X-Goog-FieldMask":
            "places.displayName,places.id,places.location",
      },
      body: json.encode(body),
    );

    final data = json.decode(response.body);

    if (!data.containsKey("places")) {
      print("❌ Nueva API no devolvió resultados");
      print(data);
      return [];
    }

    final List places = data["places"];

    return places.map<Map<String, String>>((p) {
      return {
        "description": p["displayName"]["text"] ?? "",
        "place_id": p["id"] ?? "",
      };
    }).toList();
  }

  /// Obtener coordenadas desde PlaceID → Places API (New)
  static Future<Map<String, double>?> getPlaceCoordinates(String placeId) async {
    final url = Uri.parse(
      "https://places.googleapis.com/v1/places/$placeId"
      "?fields=location",
    );

    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "X-Goog-Api-Key": apiKey,
      },
    );

    final data = json.decode(response.body);

    if (data["location"] == null) {
      print("❌ No se pudo obtener coordenadas");
      print(data);
      return null;
    }

    final loc = data["location"];

    return {
      "lat": (loc["latitude"] as num).toDouble(),
      "lng": (loc["longitude"] as num).toDouble(),
    };
  }
}
