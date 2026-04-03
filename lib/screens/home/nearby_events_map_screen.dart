import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/calendar_event.dart';

/// Full-screen map: user location, search radius (1–100 km, default 10 km), and nearby pinned events.
class NearbyEventsMapScreen extends StatefulWidget {
  const NearbyEventsMapScreen({
    super.key,
    required this.events,
    this.onEventTap,
  });

  final List<CalendarEvent> events;
  final void Function(CalendarEvent event)? onEventTap;

  @override
  State<NearbyEventsMapScreen> createState() => _NearbyEventsMapScreenState();
}

class _NearbyEventsMapScreenState extends State<NearbyEventsMapScreen> {
  final MapController _mapController = MapController();

  static const double _minKm = 1;
  static const double _maxKm = 100;

  double _radiusKm = 10;
  LatLng? _userPoint;
  bool _loadingLocation = true;
  String? _locationError;
  /// Event marker emphasized after user picks it from the bottom list.
  int? _focusedEventId;

  @override
  void initState() {
    super.initState();
    _requestLocation();
  }

  Future<void> _requestLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationError = null;
    });
    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        if (!mounted) return;
        setState(() {
          _loadingLocation = false;
          _locationError = 'Location permission is required to find events near you.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _userPoint = LatLng(pos.latitude, pos.longitude);
        _loadingLocation = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapToRadius());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingLocation = false;
        _locationError = 'Unable to get your location. Check GPS and try again.';
      });
    }
  }

  List<CalendarEvent> get _pinnedEvents =>
      widget.events.where((e) => e.latitude != null && e.longitude != null).toList();

  List<_NearbyEntry> _nearbySorted() {
    final center = _userPoint;
    if (center == null) return [];
    final maxM = _radiusKm * 1000;
    final out = <_NearbyEntry>[];
    for (final e in _pinnedEvents) {
      final lat = e.latitude!;
      final lon = e.longitude!;
      final m = Geolocator.distanceBetween(
        center.latitude,
        center.longitude,
        lat,
        lon,
      );
      if (m <= maxM) {
        out.add(_NearbyEntry(event: e, distanceMeters: m));
      }
    }
    out.sort((a, b) {
      final da = a.event.eventDate.compareTo(b.event.eventDate);
      if (da != 0) return da;
      return a.distanceMeters.compareTo(b.distanceMeters);
    });
    return out;
  }

  void _fitMapToRadius() {
    final c = _userPoint;
    if (c == null) return;
    setState(() => _focusedEventId = null);
    final rM = _radiusKm * 1000;
    final dLat = rM / 111320;
    final cosLat = math.cos(c.latitude * math.pi / 180).clamp(0.2, 1.0);
    final dLon = rM / (111320 * cosLat);
    final bounds = LatLngBounds(
      LatLng(c.latitude - dLat, c.longitude - dLon),
      LatLng(c.latitude + dLat, c.longitude + dLon),
    );
    const bottomInset = 248.0;
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 88, bottom: bottomInset, left: 20, right: 20),
      ),
    );
  }

  void _centerMapOnEvent(CalendarEvent e) {
    if (e.latitude == null || e.longitude == null) return;
    final p = LatLng(e.latitude!, e.longitude!);
    setState(() => _focusedEventId = e.id);
    _mapController.move(p, 14.5);
  }

  void _showRadiusBottomSheet() {
    final t = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Search radius',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1A1E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_radiusKm.round()} km',
                      style: t.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF4A4A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Events with a map pin inside this distance will show on the map and in the list below.',
                      style: t.bodySmall?.copyWith(
                        color: const Color(0xFF6A6A70),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderTheme.of(sheetContext).copyWith(
                        activeTrackColor: const Color(0xFFFF4A4A),
                        inactiveTrackColor: const Color(0xFFFF4A4A).withValues(alpha: 0.25),
                        thumbColor: const Color(0xFFFF3D3D),
                        overlayColor: const Color(0xFFFF4A4A).withValues(alpha: 0.2),
                      ),
                      child: Slider(
                        min: _minKm,
                        max: _maxKm,
                        divisions: (_maxKm - _minKm).round(),
                        value: _radiusKm.clamp(_minKm, _maxKm),
                        label: '${_radiusKm.round()} km',
                        onChanged: (v) {
                          setState(() => _radiusKm = v);
                          setModalState(() {});
                          _fitMapToRadius();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _monthShort(DateTime dt) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sept', 'Oct', 'Nov', 'Dec'];
    return m[dt.month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final nearby = _nearbySorted();
    final t = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          if (_loadingLocation)
            const ColoredBox(
              color: Color(0xFFE8E8EC),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_locationError != null)
            ColoredBox(
              color: const Color(0xFFE8E8EC),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _locationError!,
                        textAlign: TextAlign.center,
                        style: t.bodyLarge?.copyWith(color: const Color(0xFF3B3B3B)),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _requestLocation,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF3D3D),
                        ),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (_userPoint != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userPoint!,
                initialZoom: 11,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.brushandcoin.app',
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _userPoint!,
                      radius: _radiusKm * 1000,
                      useRadiusInMeter: true,
                      color: const Color(0xFFFF4A4A).withValues(alpha: 0.10),
                      borderColor: const Color(0xFFFF4A4A).withValues(alpha: 0.55),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userPoint!,
                      width: 36,
                      height: 36,
                      child: const Icon(
                        Icons.person_pin_circle,
                        size: 34,
                        color: Color(0xFF2564EB),
                      ),
                    ),
                    for (final e in _pinnedEvents)
                      if (Geolocator.distanceBetween(
                            _userPoint!.latitude,
                            _userPoint!.longitude,
                            e.latitude!,
                            e.longitude!,
                          ) <=
                          _radiusKm * 1000)
                        Marker(
                          point: LatLng(e.latitude!, e.longitude!),
                          width: _focusedEventId == e.id ? 46 : 38,
                          height: _focusedEventId == e.id ? 46 : 38,
                          child: Icon(
                            Icons.location_on,
                            size: _focusedEventId == e.id ? 40 : 34,
                            color: _focusedEventId == e.id
                                ? const Color(0xFFE65100)
                                : const Color(0xFFFF4A4A),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black26,
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const Spacer(),
                  if (!_loadingLocation && _locationError == null && _userPoint != null) ...[
                    Material(
                      color: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black26,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Search radius',
                        onPressed: _showRadiusBottomSheet,
                        icon: const Icon(Icons.donut_large, color: Color(0xFFFF4A4A)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.white,
                      elevation: 2,
                      shadowColor: Colors.black26,
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: 'Recenter on me',
                        onPressed: _fitMapToRadius,
                        icon: const Icon(Icons.my_location, color: Color(0xFF2564EB)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (!_loadingLocation && _locationError == null && _userPoint != null)
            Positioned(
              left: 14,
              right: 14,
              bottom: 0,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    elevation: 8,
                    shadowColor: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                          child: Text(
                            nearby.isEmpty
                                ? 'Events in radius'
                                : '${nearby.length} event${nearby.length == 1 ? '' : 's'} within ${_radiusKm.round()} km',
                            style: t.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1A1E),
                            ),
                          ),
                        ),
                      if (nearby.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Text(
                            'No events with a map location inside your search radius. '
                            'Widen the radius, or add an event with a pinned location on the map.',
                            style: t.bodySmall?.copyWith(
                              color: const Color(0xFF6A6A70),
                              height: 1.35,
                            ),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                            itemCount: nearby.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final item = nearby[i];
                              final e = item.event;
                              final km = (item.distanceMeters / 1000).toStringAsFixed(
                                item.distanceMeters >= 10000 ? 1 : 2,
                              );
                              final dateStr =
                                  '${e.eventDate.day} ${_monthShort(e.eventDate)} ${e.eventDate.year}';
                              final selected = _focusedEventId == e.id;
                              return Material(
                                color: selected
                                    ? const Color(0xFFFFF0ED)
                                    : const Color(0xFFF3F3F6),
                                borderRadius: BorderRadius.circular(14),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () => _centerMapOnEvent(e),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Icon(
                                            Icons.location_on,
                                            size: 22,
                                            color: selected
                                                ? const Color(0xFFE65100)
                                                : const Color(0xFFFF4A4A),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                e.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: t.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: const Color(0xFF141414),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '$dateStr · $km km',
                                                style: t.bodySmall?.copyWith(
                                                  color: const Color(0xFF6A6A70),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              if (e.venue.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  e.venue,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: t.bodySmall?.copyWith(
                                                    color: const Color(0xFF55565B),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                        if (widget.onEventTap != null)
                                          IconButton(
                                            tooltip: 'Event details',
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(
                                              minWidth: 36,
                                              minHeight: 36,
                                            ),
                                            icon: const Icon(
                                              Icons.info_outline,
                                              color: Color(0xFF2564EB),
                                            ),
                                            onPressed: () => widget.onEventTap!(e),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NearbyEntry {
  final CalendarEvent event;
  final double distanceMeters;

  _NearbyEntry({required this.event, required this.distanceMeters});
}
