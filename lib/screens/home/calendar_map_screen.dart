import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/calendar_event.dart';
import '../../navigation/user_profile_navigation.dart';
import '../../services/api_client.dart';
import 'nearby_events_map_screen.dart';
import '../../theme/content_spacing.dart';
import '../../widgets/common/bc_app_bar.dart';

enum _EventSortMode {
  timeEarliest,
  timeLatest,
  titleAZ,
  titleZA,
  venueAZ,
}

class CalendarMapScreen extends StatefulWidget {
  const CalendarMapScreen({super.key});

  @override
  State<CalendarMapScreen> createState() => _CalendarMapScreenState();
}

class _CalendarMapScreenState extends State<CalendarMapScreen> {
  final _apiClient = ApiClient();
  final _today = DateTime.now();
  late DateTime _activeMonth;
  late int _selectedDay;
  late Future<List<CalendarEvent>> _eventsFuture;
  _EventSortMode _eventSortMode = _EventSortMode.timeEarliest;

  @override
  void initState() {
    super.initState();
    _activeMonth = DateTime(_today.year, _today.month, 1);
    _selectedDay = _today.day;
    _eventsFuture = _loadEvents();
  }

  Future<List<CalendarEvent>> _loadEvents() async {
    final items = await _apiClient.fetchEvents();
    return items.map((m) => CalendarEvent.fromJson(m)).toList();
  }

  void _prevMonth() {
    setState(() {
      _activeMonth = DateTime(_activeMonth.year, _activeMonth.month - 1, 1);
      _selectedDay = 1;
    });
  }

  void _nextMonth() {
    setState(() {
      _activeMonth = DateTime(_activeMonth.year, _activeMonth.month + 1, 1);
      _selectedDay = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final header = _monthLabel(_activeMonth);
    final daysInMonth = DateUtils.getDaysInMonth(_activeMonth.year, _activeMonth.month);
    final firstWeekday = DateTime(_activeMonth.year, _activeMonth.month, 1).weekday; // 1..7
    final leadingBlanks = (firstWeekday % 7); // Sunday -> 0

    return Scaffold(
      appBar: const BcAppBar(),
      body: FutureBuilder<List<CalendarEvent>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  setState(() {
                    _eventsFuture = _loadEvents();
                  });
                },
                child: const Text('Retry loading events'),
              ),
            );
          }

          final allEvents = snapshot.data ?? const <CalendarEvent>[];
          final daysWithEventsInMonth = <int>{};
          for (final e in allEvents) {
            if (e.eventDate.year == _activeMonth.year &&
                e.eventDate.month == _activeMonth.month) {
              daysWithEventsInMonth.add(e.eventDate.day);
            }
          }
          final eventsOnSelectedDay = allEvents.where((e) {
            return e.eventDate.year == _activeMonth.year &&
                e.eventDate.month == _activeMonth.month &&
                e.eventDate.day == _selectedDay;
          }).toList();
          final sortedDayEvents = _sortEvents(eventsOnSelectedDay, _eventSortMode);
          final t = Theme.of(context).textTheme;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16 + kContentBelowAppBarPadding,
              16,
              16,
            ),
            children: [
              _CalendarCard(
                monthLabel: header,
                leadingBlanks: leadingBlanks,
                daysInMonth: daysInMonth,
                selectedDay: _selectedDay,
                daysWithEvents: daysWithEventsInMonth,
                onPrevMonth: _prevMonth,
                onNextMonth: _nextMonth,
                onSelectDay: (day) => setState(() => _selectedDay = day),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFFFF3D3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => NearbyEventsMapScreen(
                          events: allEvents,
                          onEventTap: (e) async {
                            final changed = await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => _EventDetailsScreen(event: e),
                              ),
                            );
                            if (changed == true && mounted) {
                              setState(() => _eventsFuture = _loadEvents());
                            }
                          },
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'Locate Events Near Me',
                    style: t.labelLarge?.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Events',
                    style: t.titleSmall?.copyWith(color: Colors.black87),
                  ),
                  const Spacer(),
                  Theme(
                    data: Theme.of(context).copyWith(
                      highlightColor: const Color(0xFFFFE4E4),
                      splashColor: const Color(0x26FF4A4A),
                    ),
                    child: PopupMenuButton<_EventSortMode>(
                      tooltip: 'Sort events',
                      initialValue: _eventSortMode,
                      onSelected: (mode) => setState(() => _eventSortMode = mode),
                      position: PopupMenuPosition.under,
                      offset: const Offset(0, 6),
                      elevation: 10,
                      shadowColor: Colors.black.withValues(alpha: 0.14),
                      surfaceTintColor: Colors.transparent,
                      color: Colors.white,
                      menuPadding: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      constraints: const BoxConstraints(minWidth: 188),
                      popUpAnimationStyle: AnimationStyle.noAnimation,
                      itemBuilder: (menuContext) {
                        final m = Theme.of(menuContext).textTheme;
                        final itemStyle = m.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF222222),
                        );
                        return [
                          PopupMenuItem(
                            value: _EventSortMode.timeEarliest,
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('Time · earliest first', style: itemStyle),
                          ),
                          PopupMenuItem(
                            value: _EventSortMode.timeLatest,
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('Time · latest first', style: itemStyle),
                          ),
                          PopupMenuItem(
                            value: _EventSortMode.titleAZ,
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('Title · A to Z', style: itemStyle),
                          ),
                          PopupMenuItem(
                            value: _EventSortMode.titleZA,
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('Title · Z to A', style: itemStyle),
                          ),
                          PopupMenuItem(
                            value: _EventSortMode.venueAZ,
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text('Venue · A to Z', style: itemStyle),
                          ),
                        ];
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Icon(
                          Icons.sort_rounded,
                          color: Colors.black.withValues(alpha: 0.75),
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (eventsOnSelectedDay.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No events on this day.',
                    style: t.bodyMedium?.copyWith(color: Colors.black54, fontWeight: FontWeight.w400),
                  ),
                ),
              for (final e in sortedDayEvents) ...[
                _EventCard(
                  day: e.eventDate.day,
                  monthShort: _monthShort(e.eventDate),
                  year: e.eventDate.year,
                  title: e.title,
                  subtitle: e.venue,
                  imageUrl: e.imageUrl,
                  onTap: () async {
                    final changed = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => _EventDetailsScreen(event: e),
                      ),
                    );
                    if (changed == true && mounted) {
                      setState(() {
                        _eventsFuture = _loadEvents();
                      });
                    }
                  },
                ),
                const SizedBox(height: 10),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final String monthLabel;
  final int leadingBlanks;
  final int daysInMonth;
  final int selectedDay;
  final Set<int> daysWithEvents;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<int> onSelectDay;

  const _CalendarCard({
    required this.monthLabel,
    required this.leadingBlanks,
    required this.daysInMonth,
    required this.selectedDay,
    required this.daysWithEvents,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
    final t = Theme.of(context).textTheme;

    final items = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      items.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final isSelected = day == selectedDay;
      final hasEvent = daysWithEvents.contains(day);
      final Color circleColor;
      final Color labelColor;
      if (isSelected) {
        circleColor = const Color(0xFFFF3D3D);
        labelColor = Colors.white;
      } else if (hasEvent) {
        circleColor = const Color(0xFFFFE4E4);
        labelColor = const Color(0xFF3B3B3B);
      } else {
        circleColor = Colors.transparent;
        labelColor = const Color(0xFF3B3B3B);
      }
      items.add(
        GestureDetector(
          onTap: () => onSelectDay(day),
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: t.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: labelColor,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE1E1E4),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onPrevMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    monthLabel,
                    textAlign: TextAlign.center,
                    style: t.titleMedium?.copyWith(color: const Color(0xFF3B3B3B)),
                  ),
                ),
                IconButton(
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final label in weekdayLabels)
                  Expanded(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: t.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: const Color(0xFFB0B0B5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 6,
              children: items,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final int day;
  final String monthShort;
  final int year;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;

  const _EventCard({
    required this.day,
    required this.monthShort,
    required this.year,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('$day', style: t.displaySmall),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monthShort,
                        style: t.titleSmall?.copyWith(color: Colors.black),
                      ),
                      Text(
                        '$year',
                        style: t.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: t.titleSmall?.copyWith(color: Colors.black87),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: t.bodySmall?.copyWith(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (imageUrl != null && imageUrl!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: _EventImage(imageUrl: imageUrl!.trim()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

int? _dayListMinutesFromTimeString(String raw) {
  var s = raw.trim().toUpperCase();
  if (s.isEmpty) return null;
  final hasAm = s.contains('AM');
  final hasPm = s.contains('PM');
  if (hasAm || hasPm) {
    s = s.replaceAll('AM', '').replaceAll('PM', '').trim();
  }
  final colon = s.indexOf(':');
  late int hour;
  var minute = 0;
  if (colon < 0) {
    final h = int.tryParse(s);
    if (h == null) return null;
    hour = h;
  } else {
    final h = int.tryParse(s.substring(0, colon).trim());
    if (h == null) return null;
    hour = h;
    final rest = s.substring(colon + 1).trim();
    final digits = RegExp(r'^\d{1,2}').stringMatch(rest) ?? '';
    minute = int.tryParse(digits) ?? 0;
  }
  if (hasAm || hasPm) {
    if (hasPm && hour != 12) hour += 12;
    if (hasAm && hour == 12) hour = 0;
  }
  return hour * 60 + minute.clamp(0, 59);
}

int? _dayListMinutesForEvent(CalendarEvent e) {
  final main = _dayListMinutesFromTimeString(e.eventTime);
  if (main != null) return main;
  for (final sch in e.schedules) {
    final m = _dayListMinutesFromTimeString(sch.time);
    if (m != null) return m;
  }
  return null;
}

int _compareEventsByTime(CalendarEvent a, CalendarEvent b, {required bool latestFirst}) {
  final ma = _dayListMinutesForEvent(a);
  final mb = _dayListMinutesForEvent(b);
  if (ma == null && mb == null) return 0;
  if (ma == null) return 1;
  if (mb == null) return -1;
  return latestFirst ? mb.compareTo(ma) : ma.compareTo(mb);
}

List<CalendarEvent> _sortEvents(List<CalendarEvent> events, _EventSortMode mode) {
  final out = List<CalendarEvent>.from(events);
  switch (mode) {
    case _EventSortMode.titleAZ:
      out.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    case _EventSortMode.titleZA:
      out.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
    case _EventSortMode.venueAZ:
      out.sort((a, b) => a.venue.toLowerCase().compareTo(b.venue.toLowerCase()));
    case _EventSortMode.timeEarliest:
      out.sort((a, b) => _compareEventsByTime(a, b, latestFirst: false));
    case _EventSortMode.timeLatest:
      out.sort((a, b) => _compareEventsByTime(a, b, latestFirst: true));
  }
  return out;
}

class _EventImage extends StatelessWidget {
  final String imageUrl;

  const _EventImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    final file = File(imageUrl);
    if (!file.existsSync()) {
      return _fallback();
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: const Color(0xFFE9E9EC),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.black45),
      ),
    );
  }
}

Widget _eventLocationMapLayers(LatLng point, double zoom) {
  return FlutterMap(
    options: MapOptions(
      initialCenter: point,
      initialZoom: zoom,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all,
      ),
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        userAgentPackageName: 'com.brushandcoin.app',
      ),
      MarkerLayer(
        markers: [
          Marker(
            point: point,
            width: 44,
            height: 44,
            child: const Icon(
              Icons.location_on,
              size: 40,
              color: Color(0xFFFF4A4A),
            ),
          ),
        ],
      ),
    ],
  );
}

/// OpenStreetMap preview for the Location tab when the event has coordinates.
class _EventLocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  const _EventLocationMap({
    required this.latitude,
    required this.longitude,
  });

  void _openFullscreen(BuildContext context) {
    final point = LatLng(latitude, longitude);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => _EventLocationFullscreenScreen(center: point),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return Stack(
      fit: StackFit.expand,
      children: [
        _eventLocationMapLayers(point, 15),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(10),
            child: IconButton(
              tooltip: 'Expand map',
              icon: const Icon(Icons.fullscreen, color: Color(0xFF1A1A1E)),
              onPressed: () => _openFullscreen(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventLocationFullscreenScreen extends StatelessWidget {
  final LatLng center;

  const _EventLocationFullscreenScreen({required this.center});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Event location',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _eventLocationMapLayers(center, 15.5),
      ),
    );
  }
}

class _EventDetailsScreen extends StatefulWidget {
  final CalendarEvent event;

  const _EventDetailsScreen({required this.event});

  @override
  State<_EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<_EventDetailsScreen> {
  int _tab = 0; // 0 details, 1 location, 2 participants
  final _apiClient = ApiClient();
  int? _currentUserId;
  bool _loadingOwner = true;
  bool _saving = false;
  late CalendarEvent _event;

  bool _participantsLoading = false;
  List<Map<String, dynamic>> _participants = [];
  bool _joinedByMe = false;
  bool _joining = false;
  String? _participantsError;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final id = await _apiClient.getCurrentUserId();
      if (!mounted) return;
      setState(() {
        _currentUserId = id;
        _loadingOwner = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingOwner = false);
    }
  }

  void _setTab(int idx) {
    setState(() => _tab = idx);
    if (idx == 2) {
      _loadParticipants();
    }
  }

  Future<void> _loadParticipants({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _participantsLoading = true;
        _participantsError = null;
      });
    }
    try {
      final data = await _apiClient.fetchEventParticipants(_event.id);
      if (!mounted) return;
      final raw = data['participants'];
      final list = <Map<String, dynamic>>[];
      if (raw is List) {
        for (final p in raw) {
          if (p is Map) {
            list.add(p.map((k, v) => MapEntry('$k', v)));
          }
        }
      }
      setState(() {
        _participants = list;
        _joinedByMe = data['joinedByMe'] == true;
        _participantsError = null;
        _participantsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (!silent) _participantsLoading = false;
        _participantsError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (!silent) _participantsLoading = false;
        _participantsError = 'Could not load participants.';
      });
    }
  }

  Future<void> _joinEventAsParticipant() async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      await _apiClient.joinEvent(_event.id);
      if (!mounted) return;
      await _loadParticipants(silent: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're on the participant list.")),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  bool _isOrganizer(CalendarEvent e) {
    if (_currentUserId == null || e.createdBy == null) return false;
    return _currentUserId == e.createdBy;
  }

  int _participantUserId(Map<String, dynamic> p) {
    final v = p['userId'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final e = _event;
    final dateText = '${e.eventDate.day} ${_monthShort(e.eventDate)} ${e.eventDate.year}';
    final timeText = e.eventTime.isEmpty ? 'TBA' : e.eventTime;

    final t = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F3F6),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Back to Events',
          style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.title,
                              style: t.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF141414),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4A4A),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              e.category.isEmpty ? 'EVENT' : e.category.toUpperCase(),
                              style: t.labelSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$dateText   •   $timeText',
                        style: t.bodyMedium?.copyWith(
                          color: const Color(0xFF55565B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        e.locationText.isEmpty ? e.venue : e.locationText,
                        style: t.bodyMedium?.copyWith(
                          color: const Color(0xFF55565B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (e.createdBy != null && e.createdBy! > 0) ...[
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => pushUserProfile(
                            context,
                            userId: e.createdBy!,
                            username: 'User',
                          ),
                          child: Text(
                            'View organizer profile',
                            style: t.bodyMedium?.copyWith(
                              color: const Color(0xFFFF4A4A),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (e.imageUrl != null && e.imageUrl!.trim().isNotEmpty) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 96,
                      height: 72,
                      child: _EventImage(imageUrl: e.imageUrl!.trim()),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFE9E9EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _tabButton('Details', 0),
                _tabButton('Location', 1),
                _tabButton('Participants', 2),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_tab == 0) ...[
            _infoCard(
              title: 'Event Description',
              content: e.description.isEmpty ? 'No description provided.' : e.description,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Schedule',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (e.schedules.isEmpty)
                    Text(
                      'No schedule added yet.',
                      style: t.bodyMedium?.copyWith(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  for (final s in e.schedules) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 72,
                            child: Text(
                              s.time.isEmpty ? 'TBA' : s.time,
                              style: t.titleSmall?.copyWith(
                                color: const Color(0xFFFF4A4A),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.name.isEmpty ? 'Activity' : s.name,
                                  style: t.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1E1F24),
                                  ),
                                ),
                                if (s.description.isNotEmpty)
                                  Text(
                                    s.description,
                                    style: t.bodySmall?.copyWith(
                                      color: const Color(0xFF6A6A70),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (_tab == 1) ...[
            if (e.latitude != null && e.longitude != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 220,
                  child: _EventLocationMap(
                    latitude: e.latitude!,
                    longitude: e.longitude!,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            _infoCard(
              title: 'Venue',
              content: e.venue.isEmpty ? 'No venue provided.' : e.venue,
            ),
            const SizedBox(height: 12),
            _infoCard(
              title: 'Address',
              content: e.locationText.isEmpty ? 'No location provided.' : e.locationText,
            ),
            if (e.latitude == null || e.longitude == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'No map pin yet — the organizer can add a location when creating or editing the event.',
                  style: t.bodySmall?.copyWith(
                    color: const Color(0xFF6A6A70),
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
          ],
          if (_tab == 2) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Participants',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  if (_participantsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_participantsError != null)
                    Text(
                      _participantsError!,
                      style: t.bodyMedium?.copyWith(
                        color: const Color(0xFFB3261E),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else if (_participants.isEmpty)
                    Text(
                      'No participants yet.',
                      style: t.bodyMedium?.copyWith(
                        color: const Color(0xFF55565B),
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    ..._participants.map((p) {
                      final uid = _participantUserId(p);
                      final name = '${p['username'] ?? 'User'}';
                      final isOrg = p['isOrganizer'] == true;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: const Color(0xFFF3F3F6),
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: uid > 0
                                ? () => pushUserProfile(
                                      context,
                                      userId: uid,
                                      username: name,
                                    )
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: t.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1E1F24),
                                          ),
                                        ),
                                        if (isOrg)
                                          Text(
                                            'Organizer',
                                            style: t.bodySmall?.copyWith(
                                              color: const Color(0xFFFF4A4A),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey.shade600,
                                    size: 22,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            if (!_loadingOwner && !_isOrganizer(e)) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: _joinedByMe
                    ? FilledButton.tonal(
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("You're attending"),
                      )
                    : FilledButton(
                        onPressed: (_joining || _participantsLoading)
                            ? null
                            : _joinEventAsParticipant,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4A4A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _joining
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Join event'),
                      ),
              ),
            ],
          ],
          if (!_loadingOwner && _canManage(e)) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _editEvent,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _deleteEvent,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4A4A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _canManage(CalendarEvent e) {
    if (_currentUserId == null || e.createdBy == null) return false;
    return _currentUserId == e.createdBy;
  }

  Future<void> _editEvent() async {
    final titleController = TextEditingController(text: _event.title);
    final venueController = TextEditingController(text: _event.venue);
    final descriptionController = TextEditingController(text: _event.description);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottom = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Event',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: venueController,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      setState(() => _saving = true);
                      try {
                        final json = await _apiClient.updateEvent(
                          eventId: _event.id,
                          title: titleController.text.trim(),
                          category: _event.category,
                          eventDate: _event.eventDate.toIso8601String().split('T').first,
                          eventTime: _event.eventTime,
                          venue: venueController.text.trim(),
                          locationText: _event.locationText,
                          latitude: _event.latitude,
                          longitude: _event.longitude,
                          description: descriptionController.text.trim(),
                          additionalInfo: _event.additionalInfo,
                          schedules: _event.schedules
                              .map((s) => {
                                    'name': s.name,
                                    'time': s.time,
                                    'description': s.description,
                                  })
                              .toList(),
                          imageUrl: _event.imageUrl,
                        );
                        if (!mounted) return;
                        final updated = CalendarEvent.fromJson(json);
                        setState(() => _event = updated);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Event updated.')),
                        );
                      } on ApiException catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(e.message)));
                      } finally {
                        if (mounted) setState(() => _saving = false);
                      }
                    },
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await _apiClient.deleteEvent(_event.id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted.')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _tabButton(String label, int idx) {
    final selected = _tab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setTab(idx),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFFF4A4A) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? Colors.white : const Color(0xFF2A2A2E),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required String content}) {
    final it = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: it.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: it.bodyMedium?.copyWith(
              color: const Color(0xFF55565B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _monthLabel(DateTime dt) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${months[dt.month - 1]} ${dt.year}';
}

String _monthShort(DateTime dt) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sept',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[dt.month - 1];
}
