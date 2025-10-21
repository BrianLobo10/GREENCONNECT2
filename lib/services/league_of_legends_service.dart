import 'dart:convert';
import 'package:http/http.dart' as http;

class LeagueOfLegendsService {
  static const String _baseUrl = 'https://ddragon.leagueoflegends.com';
  static const String _version = '14.1.1'; // Versión de Data Dragon
  
  static LeagueOfLegendsService? _instance;
  
  LeagueOfLegendsService._();
  
  static LeagueOfLegendsService get instance {
    _instance ??= LeagueOfLegendsService._();
    return _instance!;
  }

  /// Obtener URL de imagen de campeón
  static String getChampionImageUrl(String championKey) {
    return '$_baseUrl/cdn/$_version/img/champion/$championKey.png';
  }

  /// Obtener URL de splash art de campeón
  static String getChampionSplashUrl(String championKey, {int skinNumber = 0}) {
    return '$_baseUrl/cdn/img/champion/splash/${championKey}_$skinNumber.jpg';
  }

  /// Obtener lista de todos los campeones
  Future<List<Champion>> getAllChampions() async {
    try {
      final url = '$_baseUrl/cdn/$_version/data/es_MX/champion.json';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final championsData = data['data'] as Map<String, dynamic>;
        
        final champions = <Champion>[];
        championsData.forEach((key, value) {
          champions.add(Champion.fromJson(value as Map<String, dynamic>));
        });
        
        // Ordenar alfabéticamente
        champions.sort((a, b) => a.name.compareTo(b.name));
        
        return champions;
      } else {
        throw Exception('Error al cargar campeones: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al obtener campeones: $e');
    }
  }

  /// Obtener campeones populares (algunos ejemplos predefinidos)
  static List<ChampionAvatar> getPopularChampions() {
    return [
      ChampionAvatar(id: 'Ahri', name: 'Ahri'),
      ChampionAvatar(id: 'Yasuo', name: 'Yasuo'),
      ChampionAvatar(id: 'Jinx', name: 'Jinx'),
      ChampionAvatar(id: 'Lux', name: 'Lux'),
      ChampionAvatar(id: 'Zed', name: 'Zed'),
      ChampionAvatar(id: 'LeeSin', name: 'Lee Sin'),
      ChampionAvatar(id: 'Ezreal', name: 'Ezreal'),
      ChampionAvatar(id: 'Thresh', name: 'Thresh'),
      ChampionAvatar(id: 'Vayne', name: 'Vayne'),
      ChampionAvatar(id: 'Akali', name: 'Akali'),
      ChampionAvatar(id: 'KaiSa', name: 'Kai\'Sa'),
      ChampionAvatar(id: 'Katarina', name: 'Katarina'),
      ChampionAvatar(id: 'MissFortune', name: 'Miss Fortune'),
      ChampionAvatar(id: 'Ashe', name: 'Ashe'),
      ChampionAvatar(id: 'Garen', name: 'Garen'),
      ChampionAvatar(id: 'Darius', name: 'Darius'),
      ChampionAvatar(id: 'Leesin', name: 'Lee Sin'),
      ChampionAvatar(id: 'Riven', name: 'Riven'),
      ChampionAvatar(id: 'Caitlyn', name: 'Caitlyn'),
      ChampionAvatar(id: 'Teemo', name: 'Teemo'),
    ];
  }
}

class Champion {
  final String id;
  final String key;
  final String name;
  final String title;

  Champion({
    required this.id,
    required this.key,
    required this.name,
    required this.title,
  });

  factory Champion.fromJson(Map<String, dynamic> json) {
    return Champion(
      id: json['id'] as String,
      key: json['key'] as String,
      name: json['name'] as String,
      title: json['title'] as String,
    );
  }

  String get imageUrl => LeagueOfLegendsService.getChampionImageUrl(id);
}

class ChampionAvatar {
  final String id;
  final String name;

  ChampionAvatar({
    required this.id,
    required this.name,
  });

  String get imageUrl => LeagueOfLegendsService.getChampionImageUrl(id);
}

