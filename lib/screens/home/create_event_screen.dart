import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/api_client.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _scrollController = ScrollController();

  final _titleController = TextEditingController();
  final _venueController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final ApiClient _apiClient = ApiClient();

  String _category = 'Art';
  DateTime _date = DateTime.now();
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);

  final List<_EventActivity> _activities = [];

  bool _isCreating = false;
  bool _isPickingImage = false;
  File? _eventImageFile;
  LatLng? _selectedLocationPoint;

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _venueController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _additionalInfoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = '${_date.month}/${_date.day}/${_date.year}';
    final timeLabel = _time.format(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Add Event',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              top: false,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                children: [
                  _ImageUploadBox(
                    imageFile: _eventImageFile,
                    isPicking: _isPickingImage,
                    onTap: _pickEventImage,
                  ),
                  const SizedBox(height: 16),
                  _LabeledTextField(
                    label: 'Event Title',
                    controller: _titleController,
                    hint: 'Enter event title',
                    accentLabel: true,
                  ),
                  const SizedBox(height: 12),
                  _CategoryDropdown(
                    value: _category,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 12),
                  _DateTimeRow(
                    dateLabel: dateLabel,
                    timeLabel: timeLabel,
                    onPickDate: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    onPickTime: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) setState(() => _time = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  _ScheduleCard(
                    activities: _activities,
                    onAddActivity: _showAddScheduleDialog,
                  ),
                  const SizedBox(height: 12),
                  _LabeledTextField(
                    label: 'Venue',
                    controller: _venueController,
                    hint: 'Enter venue',
                    accentLabel: true,
                  ),
                  const SizedBox(height: 12),
                  _LocationCard(
                    controller: _locationController,
                    onLocationChanged: (point) => _selectedLocationPoint = point,
                  ),
                  const SizedBox(height: 12),
                  _LabeledTextField(
                    label: 'Description',
                    controller: _descriptionController,
                    hint: 'Enter description',
                    minLines: 4,
                    accentLabel: true,
                  ),
                  const SizedBox(height: 12),
                  _LabeledTextField(
                    label: 'Additional Info (Optional)',
                    controller: _additionalInfoController,
                    hint: 'Any extra details',
                    minLines: 3,
                    accentLabel: false,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4A4A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isCreating
                    ? null
                    : () async {
                        final title = _titleController.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event title is required.')),
                          );
                          return;
                        }
                        setState(() => _isCreating = true);
                        try {
                          final eventDate = _date.toIso8601String().split('T').first;
                          final hh = _time.hour.toString().padLeft(2, '0');
                          final mm = _time.minute.toString().padLeft(2, '0');
                          final eventTime = '$hh:$mm';
                          await _apiClient.createEvent(
                            title: title,
                            category: _category,
                            eventDate: eventDate,
                            eventTime: eventTime,
                            venue: _venueController.text.trim(),
                            locationText: _locationController.text.trim(),
                            latitude: _selectedLocationPoint?.latitude,
                            longitude: _selectedLocationPoint?.longitude,
                            description: _descriptionController.text.trim(),
                            additionalInfo: _additionalInfoController.text.trim(),
                            schedules: _activities
                                .map(
                                  (a) => {
                                    'name': a.title,
                                    'time': a.timeLabel,
                                    'description': a.description,
                                  },
                                )
                                .toList(),
                            imageUrl: _eventImageFile?.path,
                          );
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Event created successfully.')),
                          );
                          Navigator.of(context).pop(true);
                        } on ApiException catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text(e.message)));
                        } catch (_) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unable to create event.')),
                          );
                        } finally {
                          if (mounted) setState(() => _isCreating = false);
                        }
                      },
                child: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Event'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddScheduleDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Event Schedule',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Name of the event',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setLocalState(() => selectedTime = picked);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFBDBDBD)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'What time is the event',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6D6D72),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              selectedTime.format(ctx),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4A4A),
                        ),
                        onPressed: () {
                          final name = nameController.text.trim();
                          final description = descriptionController.text.trim();
                          if (name.isEmpty || description.isEmpty) {
                            setLocalState(() {
                              error = 'Please fill in all required fields.';
                            });
                            return;
                          }
                          setState(() {
                            _activities.add(
                              _EventActivity(
                                title: name,
                                timeLabel: selectedTime.format(ctx),
                                description: description,
                              ),
                            );
                          });
                          Navigator.of(ctx).pop();
                        },
                        child: const Text('Add Schedule'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickEventImage() async {
    if (_isPickingImage) return;

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await _pickFromSource(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFromSource(ImageSource source) async {
    if (_isPickingImage) return;
    setState(() => _isPickingImage = true);
    try {
      if (source == ImageSource.camera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Camera permission is required.')),
          );
          return;
        }
      }

      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (picked == null) return;

      final file = File(picked.path);
      final bytes = await file.length();
      // 5MB limit to match UI text.
      if (bytes > 5 * 1024 * 1024) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image is larger than 5MB.')),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _eventImageFile = file);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to pick image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }
}

class _ImageUploadBox extends StatelessWidget {
  final File? imageFile;
  final bool isPicking;
  final VoidCallback onTap;

  const _ImageUploadBox({
    required this.imageFile,
    required this.isPicking,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isPicking ? null : onTap,
        child: Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(16),
            image: imageFile != null
                ? DecorationImage(
                    image: FileImage(imageFile!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageFile == null
              ? Center(
                  child: isPicking
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: Color(0xFFFF4A4A), size: 34),
                            SizedBox(height: 8),
                            Text(
                              'Click to upload',
                              style: TextStyle(
                                color: Color(0xFF7B7B82),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'PNG/JPG up to 5MB',
                              style: TextStyle(color: Color(0xFF9B9B9F), fontSize: 12),
                            ),
                          ],
                        ),
                )
              : Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Change',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final int minLines;
  final bool accentLabel;

  const _LabeledTextField({
    required this.label,
    required this.controller,
    this.hint,
    this.minLines = 1,
    this.accentLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = accentLabel ? const Color(0xFFFF4A4A) : const Color(0xFF8C8C90);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: minLines > 1 ? minLines : 1,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: const Color(0xFFF6F6F6),
          ),
        ),
      ],
    );
  }
}

class _CategoryDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _CategoryDropdown({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const categories = ['Art', 'Design', 'Music', 'Photo', 'Culture'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFFFF4A4A),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F6F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: categories
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateTimeRow extends StatelessWidget {
  final String dateLabel;
  final String timeLabel;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _DateTimeRow({
    required this.dateLabel,
    required this.timeLabel,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniPickerCard(
            label: 'Date',
            value: dateLabel,
            icon: Icons.calendar_today_outlined,
            onTap: onPickDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniPickerCard(
            label: 'Time',
            value: timeLabel,
            icon: Icons.access_time_outlined,
            onTap: onPickTime,
          ),
        ),
      ],
    );
  }
}

class _MiniPickerCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _MiniPickerCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F6F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, size: 18, color: const Color(0xFF3B3B3B)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final List<_EventActivity> activities;
  final VoidCallback onAddActivity;

  const _ScheduleCard({
    required this.activities,
    required this.onAddActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Schedule',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF4A4A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Add activities and their times for your event schedule',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8B8B90),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: onAddActivity,
                icon: const Icon(Icons.add_circle_outline),
                color: const Color(0xFFFF4A4A),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (activities.isEmpty)
            const Text(
              'No schedules yet. Tap + to add one.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF8B8B90),
                fontWeight: FontWeight.w600,
              ),
            ),
          for (int i = 0; i < activities.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ActivityRow(activity: activities[i]),
            ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final _EventActivity activity;

  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              activity.title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFF111111),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.timeLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              if (activity.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                SizedBox(
                  width: 130,
                  child: Text(
                    activity.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A7A7F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<LatLng>? onLocationChanged;

  const _LocationCard({
    required this.controller,
    this.onLocationChanged,
  });

  @override
  State<_LocationCard> createState() => _LocationCardState();
}

class _LocationCardState extends State<_LocationCard> {
  final MapController _mapController = MapController();

  // Default around your existing sample coordinates.
  LatLng _pickedPoint = const LatLng(13.627718, 123.199912);
  double _zoom = 15.5;

  bool _isLocating = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Move map to the default point once the widget is laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_pickedPoint, _zoom);
      widget.onLocationChanged?.call(_pickedPoint);
    });
  }

  Future<void> _searchAddress() async {
    final query = widget.controller.text.trim();
    if (query.isEmpty) return;
    if (_isSearching) return;

    setState(() => _isSearching = true);
    try {
      // Nominatim search.
      // Example response: [{ "lat": "...", "lon": "...", "display_name": "..." }, ...]
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&limit=5&addressdetails=1&q=${Uri.encodeQueryComponent(query)}',
      );

      final response = await http.get(
        uri,
        headers: const {
          // Nominatim requires a User-Agent identifying the app.
          'User-Agent': 'BrushAndCoinMobile/1.0',
        },
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Search failed (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! List || decoded.isEmpty) return;

      final first = decoded.first as Map<String, dynamic>;
      final lat = double.tryParse(first['lat']?.toString() ?? '');
      final lon = double.tryParse(first['lon']?.toString() ?? '');
      if (lat == null || lon == null) return;

      final picked = LatLng(lat, lon);
      setState(() => _pickedPoint = picked);
      _mapController.move(picked, _zoom);
      widget.onLocationChanged?.call(_pickedPoint);

      final displayName = first['display_name']?.toString();
      if (displayName != null && displayName.isNotEmpty) {
        widget.controller.text = displayName;
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to search that location.')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final picked = LatLng(pos.latitude, pos.longitude);
      setState(() => _pickedPoint = picked);
      _mapController.move(picked, _zoom);
      widget.onLocationChanged?.call(_pickedPoint);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to get current location.')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _openExpandedMap() async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(
        builder: (_) => _ExpandedMapPickerScreen(
          initialPoint: _pickedPoint,
          initialZoom: _zoom,
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _pickedPoint = picked);
    _mapController.move(picked, _zoom);
    widget.onLocationChanged?.call(_pickedPoint);
  }

  @override
  Widget build(BuildContext context) {
    final latLabel = _pickedPoint.latitude.toStringAsFixed(6);
    final lonLabel = _pickedPoint.longitude.toStringAsFixed(6);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFFFF4A4A),
            ),
          ),
          const SizedBox(height: 10),
          // Map preview (tap to move the pin).
          SizedBox(
            height: 170,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _pickedPoint,
                  initialZoom: _zoom,
                  onTap: (_, latLng) {
                    setState(() => _pickedPoint = latLng);
                    widget.onLocationChanged?.call(_pickedPoint);
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.brushandcoin.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pickedPoint,
                        width: 40,
                        height: 40,
                        child: const Icon(
                          Icons.location_on,
                          size: 36,
                          color: Color(0xFFFF4A4A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openExpandedMap,
              icon: const Icon(Icons.open_in_full, size: 18),
              label: const Text('Expand map'),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter address or place',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 78,
                  height: 36,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4A4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: _isSearching ? null : _searchAddress,
                    child: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Search',
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: _isLocating ? null : _getCurrentLocation,
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('Get current location'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF3B3B3B),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Location: $latLabel, $lonLabel',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventActivity {
  final String title;
  final String timeLabel;
  final String description;

  const _EventActivity({
    required this.title,
    required this.timeLabel,
    this.description = '',
  });
}

class _ExpandedMapPickerScreen extends StatefulWidget {
  final LatLng initialPoint;
  final double initialZoom;

  const _ExpandedMapPickerScreen({
    required this.initialPoint,
    required this.initialZoom,
  });

  @override
  State<_ExpandedMapPickerScreen> createState() =>
      _ExpandedMapPickerScreenState();
}

class _ExpandedMapPickerScreenState extends State<_ExpandedMapPickerScreen> {
  final MapController _controller = MapController();
  late LatLng _pickedPoint;

  @override
  void initState() {
    super.initState();
    _pickedPoint = widget.initialPoint;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(_pickedPoint),
        ),
      ),
      body: FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: _pickedPoint,
          initialZoom: widget.initialZoom,
          onTap: (_, point) => setState(() => _pickedPoint = point),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.brushandcoin.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _pickedPoint,
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
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 46,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF4A4A),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(_pickedPoint),
              child: const Text('Use this location'),
            ),
          ),
        ),
      ),
    );
  }
}

