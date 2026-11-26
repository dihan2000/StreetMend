import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../brand.dart';
import 'report_draft.dart';
import 'services/location_service.dart';
import 'widgets/issue_map.dart';

typedef LocationMapBuilder = Widget Function(
  LatLng center,
  ValueChanged<LatLng> onMoved,
);

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({
    super.key,
    this.initial,
    this.service,
    this.mapBuilder,
  });
  final IssueLocation? initial;
  final LocationService? service;
  // Allows tests to exercise manual selection without requesting internet tiles.
  final LocationMapBuilder? mapBuilder;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late final _service = widget.service ?? LocationService();
  final _map = MapController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  // A labelled browsing starting point ONLY. Not a GPS fix or confirmed pin.
  late LatLng _center = widget.initial == null
      ? const LatLng(3.139, 101.6869)
      : LatLng(widget.initial!.latitude, widget.initial!.longitude);
  late bool _selected = widget.initial != null;
  late String _method = widget.initial?.method ?? 'manual_map';
  late double? _accuracy = widget.initial?.accuracyMeters;
  bool _coordinateDirty = false;
  final _coordinateSection = GlobalKey();
  final _mapSection = GlobalKey();
  bool _busy = false;
  bool _mapReady = false;
  bool _settings = false;
  String? _message;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initial != null) _syncFields();
  }

  void _syncFields() {
    _latitude.text = _center.latitude.toString();
    _longitude.text = _center.longitude.toString();
  }

  void _showSection(GlobalKey key) {
    _request++;
    setState(() {
      _busy = false;
      _settings = false;
    });
    Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _request++;
    _map.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  void _choose(LatLng point, String method, {double? accuracy}) {
    if (!IssueLocation.isValid(point.latitude, point.longitude)) return;
    // A manual edit supersedes any outstanding GPS response.
    _request++;
    setState(() {
      _center = point;
      _selected = true;
      _coordinateDirty = false;
      _settings = false;
      _syncFields();
      _method = method;
      _accuracy = accuracy;
      _busy = false;
      _message = null;
    });
  }

  Future<void> _gps() async {
    final request = ++_request;
    setState(() {
      _busy = true;
      _message = null;
      _settings = false;
    });
    try {
      final position = await _service.current();
      if (!mounted || request != _request) return;
      if (!IssueLocation.isValid(position.latitude, position.longitude)) {
        throw const LocationFailure(
          'The device returned an invalid location. Please choose manually.',
        );
      }
      _choose(
        LatLng(position.latitude, position.longitude),
        'gps',
        accuracy: position.accuracy,
      );
      if (_mapReady) _map.move(_center, 17);
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _busy = false;
        _message = error is LocationFailure ? error.message : 'Unable to obtain GPS. Try again or choose the location manually.';
        _settings = error is LocationFailure && error.settingsAvailable;
      });
    }
  }

  void _coordinateEdited(String _) {
    _request++;
    setState(() {
      _selected = false;
      _coordinateDirty = true;
      _accuracy = null;
      _busy = false;
      _message = 'Tap Use Entered Coordinates to validate these values before confirming.';
    });
  }

  void _coordinates() {
    final lat = double.tryParse(_latitude.text.trim());
    final lon = double.tryParse(_longitude.text.trim());
    if (!IssueLocation.isValid(lat, lon)) {
      setState(
        () => _message =
            'Enter latitude from −90 to 90 and longitude from −180 to 180.',
      );
      return;
    }
    FocusScope.of(context).unfocus();
    _choose(LatLng(lat!, lon!), 'manual_coordinates');
    if (_mapReady) _map.move(_center, 17);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: appColors(context).background,
    appBar: AppBar(title: const Text('Issue Location')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '2 of 3 • Pin the problem',
              style: TextStyle(
                color: appColors(context).ink,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Move the map beneath the pin to mark the issue, then confirm. GPS access is optional.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _gps,
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
              label: Text(
                _busy ? 'Finding your location…' : 'Use My Current Location',
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showSection(_mapSection),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Choose on Map'),
            ),
            OutlinedButton.icon(
              onPressed: () => _showSection(_coordinateSection),
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text('Manual Location'),
            ),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _message!,
                  style: TextStyle(color: appColors(context).ink),
                ),
              ),
            if (_settings)
              TextButton(
                onPressed: () async {
                  final opened = await _service.openSettings();
                  if (!mounted) return;
                  setState(
                    () => _message = opened
                        ? 'After enabling access, return here and tap Use My Location.'
                        : 'Open your device Settings to change location access, or choose manually.',
                  );
                },
                child: const Text('Open Settings'),
              ),
            const SizedBox(height: 12),
            KeyedSubtree(
              key: _mapSection,
              child:
                  widget.mapBuilder?.call(
                    _center,
                    (point) => _choose(point, 'manual_map'),
                  ) ??
                  IssueMap(
                    center: _center,
                    controller: _map,
                    onReady: () {
                      _mapReady = true;
                      _map.move(_center, 15);
                    },
                    onMoved: (point) => _choose(point, 'manual_map'),
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _selected
                  ? 'Selected: ${_center.latitude.toStringAsFixed(6)}, ${_center.longitude.toStringAsFixed(6)}'
                  : _coordinateDirty
                  ? 'Coordinates edited but not applied. The map still shows the previous view; apply valid coordinates before confirming.'
                  : 'Starting map view: Kuala Lumpur. This is not your GPS location. Move the map or enter coordinates to select an issue location.',
              style: TextStyle(
                color: appColors(context).ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_selected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Source: ${_method == 'gps'
                      ? 'Device location (GPS/browser)'
                      : _method == 'manual_map'
                      ? 'Map selection'
                      : 'Manual coordinates'} • Awaiting your confirmation',
                ),
              ),
            if (_accuracy != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Device-reported accuracy: about ${_accuracy!.toStringAsFixed(0)} m. Check the pin; GPS may be approximate.',
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Map imagery is supplied by OpenStreetMap. Loading tiles shares your IP address and viewed map area with the provider.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 20),
            Text(
              key: _coordinateSection,
              'Manual Location',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: appColors(context).ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Road and landmark search is not available yet. Enter coordinates or choose the issue position on the map. Location notes do not perform a search.',
            ),
            TextField(
              controller: _latitude,
              onChanged: _coordinateEdited,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: '−90 to 90',
              ),
            ),
            TextField(
              controller: _longitude,
              onChanged: _coordinateEdited,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: '−180 to 180',
              ),
            ),
            TextButton(
              onPressed: _coordinates,
              child: const Text('Use Entered Coordinates'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: !_selected || _busy
                  ? null
                  : () => Navigator.of(context).pop(
                      IssueLocation(
                        latitude: _center.latitude,
                        longitude: _center.longitude,
                        method: _method,
                        confirmedAt: DateTime.now(),
                        accuracyMeters: _accuracy,
                      ),
                    ),
              child: const Text('Confirm This Location'),
            ),
          ],
        ),
      ),
    ),
  );
}
