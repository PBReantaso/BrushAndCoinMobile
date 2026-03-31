import 'package:flutter/material.dart';

import '../../widgets/common/bc_app_bar.dart';

class CalendarMapScreen extends StatefulWidget {
  const CalendarMapScreen({super.key});

  @override
  State<CalendarMapScreen> createState() => _CalendarMapScreenState();
}

class _CalendarMapScreenState extends State<CalendarMapScreen> {
  final _today = DateTime.now();
  late DateTime _activeMonth;
  late int _selectedDay;

  @override
  void initState() {
    super.initState();
    _activeMonth = DateTime(_today.year, _today.month, 1);
    _selectedDay = _today.day;
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _CalendarCard(
            monthLabel: header,
            leadingBlanks: leadingBlanks,
            daysInMonth: daysInMonth,
            selectedDay: _selectedDay,
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
              onPressed: () {},
              child: const Text(
                'Locate Events Near Me',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Events',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          _EventCard(
            day: _selectedDay,
            monthShort: _monthShort(_activeMonth),
            year: _activeMonth.year,
            title: 'Bicol Cosplay Arena',
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  final String monthLabel;
  final int leadingBlanks;
  final int daysInMonth;
  final int selectedDay;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<int> onSelectDay;

  const _CalendarCard({
    required this.monthLabel,
    required this.leadingBlanks,
    required this.daysInMonth,
    required this.selectedDay,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    const weekdayLabels = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

    final items = <Widget>[];
    for (int i = 0; i < leadingBlanks; i++) {
      items.add(const SizedBox.shrink());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final isSelected = day == selectedDay;
      items.add(
        GestureDetector(
          onTap: () => onSelectDay(day),
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF3D3D) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$day',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF3B3B3B),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF3B3B3B),
                    ),
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
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: Color(0xFFB0B0B5),
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

  const _EventCard({
    required this.day,
    required this.monthShort,
    required this.year,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F3),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$day',
                style: const TextStyle(
                  fontSize: 46,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthShort,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    '$year',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFFEC4899),
                    Color(0xFF3B82F6),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(Icons.image, color: Colors.white70, size: 38),
              ),
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
