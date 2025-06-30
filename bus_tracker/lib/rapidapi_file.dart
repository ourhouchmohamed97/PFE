import 'dart:convert';
import 'package:http/http.dart' as http;

Future<List<String>> fetchBrandSuggestions(String query) async {
  final uri = Uri.https(
    'car-api2.p.rapidapi.com',
    '/api/makes',
    {
      'sort': 'id',
      'direction': 'asc',
      'verbose': 'yes',
    },
  );

  try {
    final response = await http.get(
      uri,
      headers: {
        'X-RapidAPI-Key': '2cdc31e33fmsh484d3a30022930ap1bde81jsn9d05d1360cc1',
        'X-RapidAPI-Host': 'car-api2.p.rapidapi.com',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is Map && data['data'] is List) {
        final List<dynamic> brands = data['data'];
        return brands
            .map((brand) => brand['name']?.toString() ?? '')
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
      return [];
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}

Future<List<String>> fetchModelSuggestions(String brand, String query) async {
  final uri = Uri.https(
    'car-api2.p.rapidapi.com',
    '/api/models',
    {
      'make': brand.toLowerCase(),
      'sort': 'id',
      'direction': 'asc',
      'year': '2020',
      'verbose': 'yes',
    },
  );

  try {
    final response = await http.get(
      uri,
      headers: {
        'X-RapidAPI-Key': '2cdc31e33fmsh484d3a30022930ap1bde81jsn9d05d1360cc1',
        'X-RapidAPI-Host': 'car-api2.p.rapidapi.com',
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final List<dynamic> models = decoded['data'];
      return models
          .map((model) => model['name'].toString())
          .where((name) => name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}
