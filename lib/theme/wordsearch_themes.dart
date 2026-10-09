import 'package:flutter/material.dart';

/// Theme, letter-tile style and word-category catalog for Word Search.
///
/// Every theme lives in the same physical-material world as the game logo:
/// kraft paper, carved wood, ivory, chalk, leather, copper, sea glass —
/// the variety comes from different papers, woods and inks. No neon, no
/// futuristic aesthetics: a wooden letter-tile workshop in every theme.
class WorkshopThemeDef {
  final String id;
  final String name;
  final Color paper; // desk/paper background
  final Color paperDeep; // darker desk edge / backdrop
  final Color tile; // letter tile face
  final Color tileEdge; // tile bevel edge
  final Color ink; // letter ink
  final Color accent; // found-word ribbon / highlights
  final Color accentDark;
  final Color pencil; // selection stroke color
  final Color soft; // chips, cards

  const WorkshopThemeDef({
    required this.id,
    required this.name,
    required this.paper,
    required this.paperDeep,
    required this.tile,
    required this.tileEdge,
    required this.ink,
    required this.accent,
    required this.accentDark,
    required this.pencil,
    required this.soft,
  });
}

class WorkshopThemes {
  /// First 4 themes are FREE. The rest are PRO.
  static const List<String> freeThemeIds = [
    'pine',
    'birch',
    'mahogany',
    'walnut',
  ];

  static bool isProTheme(String id) => !freeThemeIds.contains(id);

  static const List<WorkshopThemeDef> all = [
    WorkshopThemeDef(
      id: 'pine',
      name: 'Classic Pine',
      paper: Color(0xFFE9D9B8),
      paperDeep: Color(0xFF2A2016),
      tile: Color(0xFFF5E9CF),
      tileEdge: Color(0xFFC9A86A),
      ink: Color(0xFF4A3319),
      accent: Color(0xFF7A9B3F),
      accentDark: Color(0xFF4E6A24),
      pencil: Color(0xFFB4540A),
      soft: Color(0xFFDFCDA3),
    ),
    WorkshopThemeDef(
      id: 'birch',
      name: 'Birch Cabin',
      paper: Color(0xFFF1E7D2),
      paperDeep: Color(0xFF3A3A34),
      tile: Color(0xFFFDF8EC),
      tileEdge: Color(0xFFD9C9A8),
      ink: Color(0xFF3F3A2E),
      accent: Color(0xFFC0872E),
      accentDark: Color(0xFF8F611C),
      pencil: Color(0xFF7A4A16),
      soft: Color(0xFFE8DCC0),
    ),
    WorkshopThemeDef(
      id: 'mahogany',
      name: 'Mahogany Study',
      paper: Color(0xFFE4CFA8),
      paperDeep: Color(0xFF241309),
      tile: Color(0xFFF7ECD4),
      tileEdge: Color(0xFFB08B54),
      ink: Color(0xFF5A2E14),
      accent: Color(0xFFA3392B),
      accentDark: Color(0xFF732018),
      pencil: Color(0xFF5A2E14),
      soft: Color(0xFFDCC398),
    ),
    WorkshopThemeDef(
      id: 'walnut',
      name: 'Walnut Den',
      paper: Color(0xFFD9C49A),
      paperDeep: Color(0xFF1D1710),
      tile: Color(0xFFF0E2C2),
      tileEdge: Color(0xFF9A7A48),
      ink: Color(0xFF3E2A14),
      accent: Color(0xFF2E6F8E),
      accentDark: Color(0xFF1C4E66),
      pencil: Color(0xFFB4762A),
      soft: Color(0xFFCDB485),
    ),
    WorkshopThemeDef(
      id: 'desert',
      name: 'Desert Dune',
      paper: Color(0xFFF0DCB4),
      paperDeep: Color(0xFF3A2A18),
      tile: Color(0xFFFBF0D8),
      tileEdge: Color(0xFFD4B271),
      ink: Color(0xFF6B4518),
      accent: Color(0xFFC26A1B),
      accentDark: Color(0xFF8E4A10),
      pencil: Color(0xFF93310E),
      soft: Color(0xFFE6CC9C),
    ),
    WorkshopThemeDef(
      id: 'slate',
      name: 'Slate Workshop',
      paper: Color(0xFFD8D5CC),
      paperDeep: Color(0xFF23252B),
      tile: Color(0xFFEFEDE6),
      tileEdge: Color(0xFFA9A69B),
      ink: Color(0xFF2E3138),
      accent: Color(0xFF4A6FA5),
      accentDark: Color(0xFF2E4D77),
      pencil: Color(0xFF2E3138),
      soft: Color(0xFFC9C5B8),
    ),
    WorkshopThemeDef(
      id: 'olive',
      name: 'Olive Grove',
      paper: Color(0xFFE7DFC4),
      paperDeep: Color(0xFF232A17),
      tile: Color(0xFFF6F0DA),
      tileEdge: Color(0xFFB3A67E),
      ink: Color(0xFF40492A),
      accent: Color(0xFF6E7F2E),
      accentDark: Color(0xFF4A5A1C),
      pencil: Color(0xFF5A3A10),
      soft: Color(0xFFD9CFAD),
    ),
    WorkshopThemeDef(
      id: 'terracotta',
      name: 'Sunset Terracotta',
      paper: Color(0xFFEDCFA8),
      paperDeep: Color(0xFF2E1A10),
      tile: Color(0xFFFAE8CB),
      tileEdge: Color(0xFFC4935E),
      ink: Color(0xFF5E2F16),
      accent: Color(0xFFB5502A),
      accentDark: Color(0xFF7E3618),
      pencil: Color(0xFF7E3618),
      soft: Color(0xFFE2BE92),
    ),
    WorkshopThemeDef(
      id: 'seaglass',
      name: 'Sea Glass Shore',
      paper: Color(0xFFDEE8DE),
      paperDeep: Color(0xFF1C2B26),
      tile: Color(0xFFF1F6F0),
      tileEdge: Color(0xFFA9BFA8),
      ink: Color(0xFF2A463E),
      accent: Color(0xFF2E8B7A),
      accentDark: Color(0xFF1C5F54),
      pencil: Color(0xFF14455E),
      soft: Color(0xFFCCD9CC),
    ),
    WorkshopThemeDef(
      id: 'cherry',
      name: 'Cherry Orchard',
      paper: Color(0xFFF2DCC8),
      paperDeep: Color(0xFF2E1418),
      tile: Color(0xFFFBEEE0),
      tileEdge: Color(0xFFD3A67E),
      ink: Color(0xFF5E2A2A),
      accent: Color(0xFFB03A4A),
      accentDark: Color(0xFF7E2430),
      pencil: Color(0xFF5E2A2A),
      soft: Color(0xFFE8C9AC),
    ),
    WorkshopThemeDef(
      id: 'snowfield',
      name: 'Snowfield Lodge',
      paper: Color(0xFFE9EFF2),
      paperDeep: Color(0xFF1E2830),
      tile: Color(0xFFFAFCFD),
      tileEdge: Color(0xFFB8C4CE),
      ink: Color(0xFF2E3E4E),
      accent: Color(0xFF2E6E8E),
      accentDark: Color(0xFF1C4A64),
      pencil: Color(0xFF8E2E2E),
      soft: Color(0xFFD7E1E8),
    ),
    WorkshopThemeDef(
      id: 'midnight',
      name: 'Midnight Ink',
      paper: Color(0xFF3A3F52),
      paperDeep: Color(0xFF10121A),
      tile: Color(0xFFF2EEE2),
      tileEdge: Color(0xFF8E8FA3),
      ink: Color(0xFF23253A),
      accent: Color(0xFFC9A227),
      accentDark: Color(0xFF8A6D1A),
      pencil: Color(0xFFE8CE7A),
      soft: Color(0xFF2E3348),
    ),
  ];

  static WorkshopThemeDef byId(String id, {WorkshopThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Letter-tile visual styles (shapes/materials of the grid tiles).
class TileStyles {
  /// First 2 styles are FREE. The rest are PRO.
  static const List<String> names = [
    'Beveled Wood',
    'Ivory Bone',
    'Kraft Card',
    'Slate Chalk',
    'Leather Tag',
    'Copper Plate',
    'Sea Glass',
    'Carved Marble',
  ];

  static const List<String> freeStyleIds = ['0', '1'];
  static bool isPro(int v) => !freeStyleIds.contains('$v');

  /// Per-style tile face/edge modifiers applied over the theme.
  static const List<Map<String, int>> face = [
    {'tile': 0x00000000, 'edge': 0x00000000, 'radius': 8}, // beveled wood: theme colors
    {'tile': 0xFFFFFBF0, 'edge': 0xFFE0D2B0, 'radius': 10}, // ivory bone
    {'tile': 0x00000000, 'edge': 0x00000000, 'radius': 2}, // kraft card: squarer
    {'tile': 0xFFF6F4EE, 'edge': 0xFF9A9AA0, 'radius': 12}, // slate chalk
    {'tile': 0x00000000, 'edge': 0x00000000, 'radius': 18}, // leather tag: rounder
    {'tile': 0xFFF3E4CE, 'edge': 0xFFB08050, 'radius': 8}, // copper plate
    {'tile': 0xFFE4F2EF, 'edge': 0xFF8FB8AE, 'radius': 14}, // sea glass
    {'tile': 0xFFFBFBF8, 'edge': 0xFFC8C8C0, 'radius': 6}, // carved marble
  ];
}

/// Word categories. First 2 are FREE.
class WordCategories {
  static const List<String> names = [
    'Animals',
    'Food',
    'Nature',
    'Space',
    'Sports',
    'Mixed',
  ];
  static const List<String> freeCategoryIds = ['0', '1'];
  static bool isPro(int v) => !freeCategoryIds.contains('$v');

  static const Map<String, List<String>> words = {
    'Animals': [
      'LION', 'TIGER', 'ZEBRA', 'PANDA', 'KOALA', 'OTTER', 'LLAMA', 'SLOTH',
      'EAGLE', 'SHARK', 'WHALE', 'SNAKE', 'MONKEY', 'GIRAFFE', 'HIPPO', 'RHINO',
      'BEAR', 'WOLF', 'FOX', 'DEER', 'MOUSE', 'HORSE', 'SHEEP', 'GOAT',
      'CRAB', 'FROG', 'TOAD', 'LIZARD', 'TURTLE', 'RABBIT', 'BADGER', 'BEAVER',
      'CAMEL', 'COUGAR', 'JAGUAR', 'LEOPARD', 'CHEETAH', 'HYENA', 'DONKEY',
    ],
    'Food': [
      'PIZZA', 'PASTA', 'BREAD', 'CHEESE', 'APPLE', 'BANANA', 'ORANGE',
      'GRAPE', 'MELON', 'LEMON', 'HONEY', 'SUGAR', 'SALAD', 'SOUP',
      'STEAK', 'CHICKEN', 'FISH', 'RICE', 'BEANS', 'CORN', 'CARROT',
      'POTATO', 'TOMATO', 'ONION', 'GARLIC', 'PEPPER', 'CAKE', 'COOKIE',
      'DONUT', 'MUFFIN', 'CANDY', 'CHOCO', 'MILK', 'JUICE', 'WATER',
    ],
    'Nature': [
      'TREE', 'FLOWER', 'RIVER', 'MOUNTAIN', 'OCEAN', 'FOREST', 'DESERT',
      'CLOUD', 'RAIN', 'SUN', 'MOON', 'STAR', 'LEAF', 'STONE', 'SAND',
      'WIND', 'STORM', 'MEADOW', 'VALLEY', 'HILL', 'LAKE', 'POND',
      'GRASS', 'BRANCH', 'ROOT', 'BLOSSOM', 'PETAL', 'SEED', 'MOSS',
      'CORAL', 'REEF', 'ISLAND', 'CANYON', 'CLIFF', 'CAVE',
    ],
    'Space': [
      'PLANET', 'STAR', 'MOON', 'COMET', 'ASTEROID', 'GALAXY', 'NEBULA',
      'ORBIT', 'ROCKET', 'SATELLITE', 'MARS', 'VENUS', 'JUPITER',
      'SATURN', 'MERCURY', 'URANUS', 'NEPTUNE', 'EARTH', 'COSMOS',
      'LUNAR', 'SOLAR', 'ECLIPSE', 'METEOR', 'GRAVITY', 'TELESCOPE',
      'ASTRONAUT', 'SPACESHIP', 'BLACKHOLE', 'QUASAR', 'PULSAR',
    ],
    'Sports': [
      'SOCCER', 'TENNIS', 'GOLF', 'SWIM', 'RUN', 'JUMP', 'SKI', 'SURF',
      'BOXING', 'KARATE', 'YOGA', 'DANCE', 'CYCLING', 'ROWING', 'SAIL',
      'ARCHERY', 'FENCING', 'HOCKEY', 'RUGBY', 'CRICKET', 'BASEBALL',
      'BASKET', 'VOLLEY', 'BADMINTON', 'MARATHON', 'SPRINT', 'JOGGING',
      'CLIMBING', 'DIVING', 'SKATING', 'SKATEBOARD', 'TRIATHLON',
    ],
    'Mixed': [
      'PUZZLE', 'HAPPY', 'SMILE', 'FRIEND', 'MAGIC', 'DREAM', 'MUSIC',
      'DANCE', 'LIGHT', 'SHADOW', 'COLOR', 'PAINT', 'BRUSH', 'BOOK',
      'STORY', 'POEM', 'SONG', 'DRUM', 'GUITAR', 'PIANO', 'VIOLIN',
      'FLUTE', 'CANDLE', 'LANTERN', 'MIRROR', 'CLOCK', 'KEY', 'DOOR',
      'WINDOW', 'GARDEN', 'BRIDGE', 'CASTLE', 'KING', 'QUEEN', 'KNIGHT',
    ],
  };

  /// Pick [count] words of length <= [maxLen] from category [index].
  static List<String> pick(int category, int count, int maxLen) {
    final pool = List<String>.from(words[names[category.clamp(0, names.length - 1)]]!);
    pool.shuffle();
    final out = <String>[];
    for (final w in pool) {
      final clean = w.replaceAll(RegExp(r'[^A-Z]'), '');
      if (clean.length >= 3 && clean.length <= maxLen && !out.contains(clean)) {
        out.add(clean);
        if (out.length == count) break;
      }
    }
    return out;
  }
}

/// Difficulty tiers: word length / grid size / word count.
class DifficultyTiers {
  static const List<String> names = ['Cozy', 'Clever', 'Master'];
  static const List<int> gridSize = [8, 10, 12];
  static const List<int> wordCount = [6, 8, 10];
  static const List<int> maxWordLen = [5, 7, 9];
  static const List<int> timeLimitSec = [180, 240, 300]; // timed mode
  static bool isPro(int v) => v == 2; // Master is PRO
}
