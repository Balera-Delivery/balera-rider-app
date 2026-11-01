import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../constants/app_colors.dart';

class RouteMapWidget extends StatefulWidget {
  final bool isInteractive;
  final VoidCallback? onEndTrip;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final double? riderLat;
  final double? riderLng;

  const RouteMapWidget({
    super.key,
    this.isInteractive = true,
    this.onEndTrip,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.riderLat,
    this.riderLng,
  });

  @override
  State<RouteMapWidget> createState() => _RouteMapWidgetState();
}

class _RouteMapWidgetState extends State<RouteMapWidget> {
  late final MapController _mapController;

  // Default coordinate: Bale Robe, Ethiopia
  static const ll.LatLng _defaultCenter = ll.LatLng(7.0083, 39.9833);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant RouteMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.riderLat != null && widget.riderLng != null &&
        (oldWidget.riderLat != widget.riderLat || oldWidget.riderLng != widget.riderLng)) {
      _mapController.move(ll.LatLng(widget.riderLat!, widget.riderLng!), _mapController.camera.zoom);
    }
  }

  void _reCenterMap() {
    final target = (widget.riderLat != null && widget.riderLng != null)
        ? ll.LatLng(widget.riderLat!, widget.riderLng!)
        : ((widget.pickupLat != null && widget.pickupLng != null)
            ? ll.LatLng(widget.pickupLat!, widget.pickupLng!)
            : _defaultCenter);
    _mapController.move(target, 15.0);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // 1. Pickup Marker
    if (widget.pickupLat != null && widget.pickupLng != null) {
      markers.add(
        Marker(
          point: ll.LatLng(widget.pickupLat!, widget.pickupLng!),
          width: 50,
          height: 60,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 30),
              Icon(Icons.location_on, color: Color(0xFF059669), size: 24),
            ],
          ),
        ),
      );
    }

    // 2. Destination Marker
    if (widget.destinationLat != null && widget.destinationLng != null) {
      markers.add(
        Marker(
          point: ll.LatLng(widget.destinationLat!, widget.destinationLng!),
          width: 50,
          height: 60,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_rounded, color: AppColors.danger, size: 28),
              Icon(Icons.location_on, color: AppColors.danger, size: 24),
            ],
          ),
        ),
      );
    }

    // 3. Live Rider Marker
    final riderPos = (widget.riderLat != null && widget.riderLng != null)
        ? ll.LatLng(widget.riderLat!, widget.riderLng!)
        : (widget.pickupLat != null && widget.pickupLng != null
            ? ll.LatLng(widget.pickupLat! + 0.002, widget.pickupLng! + 0.002)
            : _defaultCenter);

    markers.add(
      Marker(
        point: riderPos,
        width: 54,
        height: 54,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 3,
              ),
            ],
            border: Border.all(color: AppColors.primary, width: 2.5),
          ),
          child: const Center(
            child: Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 26),
          ),
        ),
      ),
    );

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final points = <ll.LatLng>[];

    if (widget.pickupLat != null && widget.pickupLng != null) {
      points.add(ll.LatLng(widget.pickupLat!, widget.pickupLng!));
    }
    if (widget.riderLat != null && widget.riderLng != null) {
      points.add(ll.LatLng(widget.riderLat!, widget.riderLng!));
    }
    if (widget.destinationLat != null && widget.destinationLng != null) {
      points.add(ll.LatLng(widget.destinationLat!, widget.destinationLng!));
    }

    if (points.length < 2) return [];

    return [
      Polyline(
        points: points,
        strokeWidth: 4.5,
        color: AppColors.primary,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = (widget.riderLat != null && widget.riderLng != null)
        ? ll.LatLng(widget.riderLat!, widget.riderLng!)
        : ((widget.pickupLat != null && widget.pickupLng != null)
            ? ll.LatLng(widget.pickupLat!, widget.pickupLng!)
            : _defaultCenter);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 15.0,
            minZoom: 5.0,
            maxZoom: 18.5,
          ),
          children: [
            // OpenStreetMap High-Resolution Tile Layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.baleradelivery.balera_rider_app',
              maxZoom: 19,
              errorTileCallback: (tile, error, stackTrace) {
                // Silently handle offline/network unavailable state
              },
            ),

            // Polyline delivery route
            PolylineLayer(
              polylines: _buildPolylines(),
            ),

            // Markers
            MarkerLayer(
              markers: _buildMarkers(),
            ),
          ],
        ),

        // Floating Controls (Zoom in, Zoom out, Re-center)
        Positioned(
          right: 14,
          bottom: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMapButton(
                icon: Icons.add,
                onPressed: () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                },
              ),
              const SizedBox(height: 8),
              _buildMapButton(
                icon: Icons.remove,
                onPressed: () {
                  _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                },
              ),
              const SizedBox(height: 8),
              _buildMapButton(
                icon: Icons.my_location_rounded,
                onPressed: _reCenterMap,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
