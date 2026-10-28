// lib/models/player.dart
import 'package:flutter/foundation.dart';

class PlayerModel extends ChangeNotifier {
  // This holds the local player info (id, name). In a full app you would get id from server.
  String playerId = '';
  String name = '';
  // You can extend this model with health, avatar, etc.

  void setPlayer(String id, String displayName) {
    playerId = id;
    name = displayName;
    notifyListeners();
  }
}
