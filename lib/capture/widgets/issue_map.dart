import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../brand.dart';

/// No GPS calls here. A map view alone never requests location permission.
class IssueMap extends StatefulWidget {
  const IssueMap({
    super.key,
    required this.center,
    this.controller,
    this.onMoved,
    this.onReady,
    this.tileProvider,
  });
  final LatLng center;
  final MapController? controller;
  final ValueChanged<LatLng>? onMoved;
  final VoidCallback? onReady;
  final TileProvider? tileProvider;

  @override
  State<IssueMap> createState() => _IssueMapState();
}

class _IssueMapState extends State<IssueMap> {
  bool _tileFailed = false;
  bool _ready = false;
  final _ownedController = MapController();
  MapController get _controller => widget.controller ?? _ownedController;

  @override
  void didUpdateWidget(covariant IssueMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    // initialCenter only applies once. Keep later GPS/manual/review updates aligned.
    if (_ready &&
        oldWidget.center != widget.center &&
        _controller.camera.center != widget.center) {
      _controller.move(widget.center, _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _ownedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 300,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: widget.center,
              initialZoom: 15,
              onMapReady: () {
                _ready = true;
                widget.onReady?.call();
              },
              interactionOptions: InteractionOptions(
                flags: widget.onMoved == null
                    ? InteractiveFlag.none
                    : InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onPositionChanged: (camera, gesture) {
                if (gesture) widget.onMoved?.call(camera.center);
              },
            ),
            children: [
              TileLayer(
                tileProvider: widget.tileProvider,
                urlTemplate: const String.fromEnvironment(
                  'MAP_TILE_URL',
                  defaultValue:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                userAgentPackageName: 'com.example.streetmend_mobile',
                // flutter_map's native disk cache respects HTTP cache headers.
                errorTileCallback: (_, error, stack) {
                  if (_tileFailed) return;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_tileFailed) {
                      setState(() => _tileFailed = true);
                    }
                  });
                },
              ),
            ],
          ),
          const Center(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(
                  Icons.location_pin,
                  size: 48,
                  color: kOceanNavy,
                  shadows: [Shadow(color: Colors.white, blurRadius: 4)],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ColoredBox(
              color: appColors(context).surface,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '© OpenStreetMap contributors • ODbL\nhttps://www.openstreetmap.org/copyright',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: appColors(context).ink),
                ),
              ),
            ),
          ),
          if (_tileFailed)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Material(
                color: appColors(context).background,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Map images could not load. Check your connection or enter coordinates below.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
