// lib/main.dart - entry point for GPS Battle Royale Flutter client
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'models/player.dart';
import 'services/socket_service.dart';
import 'services/location_service.dart';

void main() {
  runApp(const FreeFireGPSApp());
}

class FreeFireGPSApp extends StatelessWidget {
  const FreeFireGPSApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SocketService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => PlayerModel()),
      ],
      child: MaterialApp(
        title: 'FreeFire GPS',
        theme: ThemeData(primarySwatch: Colors.indigo),
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GoogleMapController _mapCtrl;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    final socket = context.read<SocketService>();
    final loc = context.read<LocationService>();
    socket.connect();
    loc.startListening();
    // forward location updates to server
    loc.addListener(() {
      if (socket.connected && loc.currentLocation != null) {
        socket.emit('location', {
          'playerId': socket.playerId,
          'lat': loc.currentLocation!.latitude,
          'lng': loc.currentLocation!.longitude,
        });
      }
    });
    // listen for player list updates
    socket.on('players_update', (data) {
      final List players = data as List;
      setState(() {
        _markers.clear();
        for (var p in players) {
          if (p['lat'] != null && p['lng'] != null) {
            _markers.add(
              Marker(
                markerId: MarkerId(p['id']),
                position: LatLng(p['lat'], p['lng']),
                infoWindow: InfoWindow(title: p['name'], snippet: p['alive'] ? 'Alive' : 'Dead'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  p['alive'] ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
                ),
              ),
            );
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<LocationService>().currentLocation;
    return Scaffold(
      appBar: AppBar(title: const Text('FreeFire GPS Battle Royale')),
      body: location == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(location.latitude, location.longitude),
                zoom: 15,
              ),
              onMapCreated: (ctrl) => _mapCtrl = ctrl,
              markers: _markers,
              myLocationEnabled: true,
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shootNearest,
        label: const Text('Shoot'),
        icon: const Icon(Icons.gps_fixed),
      ),
    );
  }

  void _shootNearest() async {
    // simple nearest‑player logic (client‑side for demo)
    final socket = context.read<SocketService>();
    final loc = context.read<LocationService>().currentLocation;
    if (loc == null) return;
    final players = socket.latestPlayers;
    double? minDist;
    String? targetId;
    for (var p in players) {
      if (p['id'] == socket.playerId) continue;
      if (p['lat'] == null || p['lng'] == null) continue;
      final d = _haversine(
        loc.latitude,
        loc.longitude,
        p['lat'] as double,
        p['lng'] as double,
      );
      if (minDist == null || d < minDist) {
        minDist = d;
        targetId = p['id'];
      }
    }
    if (targetId != null && minDist! <= 30) {
      socket.emit('shoot', {'shooterId': socket.playerId, 'targetId': targetId});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No target in range')));
    }
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000; // metres
    final dLat = (lat2 - lat1) * 3.141592653589793 / 180;
    final dLon = (lon2 - lon1) * 3.141592653589793 / 180;
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) + cos(lat1 * 3.141592653589793 / 180) * cos(lat2 * 3.141592653589793 / 180) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }
}
