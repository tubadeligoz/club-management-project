import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
// O GEREKSİZ SATIRI SİLDİK (intl paketi)

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Etkinlikleri tutacağımız yapı: { Tarih: [Etkinlik1, Etkinlik2] }
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _fetchEvents();
  }

  // Firebase'den etkinlikleri çekip takvime uygun hale getirme
  Future<void> _fetchEvents() async {
    var snapshot = await FirebaseFirestore.instance.collection('posts').get();
    
    Map<DateTime, List<Map<String, dynamic>>> loadedEvents = {};

    for (var doc in snapshot.docs) {
      var data = doc.data();
      if (data['date'] != null) {
        // Firestore Timestamp'ini DateTime'a çevir
        DateTime date = (data['date'] as Timestamp).toDate();
        
        // Saati sıfırla (Sadece gün önemli)
        DateTime dateKey = DateTime(date.year, date.month, date.day);

        if (loadedEvents[dateKey] == null) {
          loadedEvents[dateKey] = [];
        }
        loadedEvents[dateKey]!.add(data);
      }
    }

    setState(() {
      _events = loadedEvents;
      _isLoading = false;
    });
  }

  // O günün etkinliklerini getiren yardımcı fonksiyon
  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    DateTime dateKey = DateTime(day.year, day.month, day.day);
    return _events[dateKey] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Etkinlik Takvimi"), centerTitle: true),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
          children: [
            // --- TAKVİM KISMI ---
            TableCalendar(
              firstDay: DateTime.utc(2023, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              
              // Seçili gün ayarı
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              
              // Format değiştirme (Haftalık/Aylık)
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },

              // ETKİNLİK YÜKLEYİCİ (Noktaları koyan kısım)
              eventLoader: _getEventsForDay,

              // Tasarım Ayarları
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(color: Colors.indigoAccent, shape: BoxShape.circle),
                selectedDecoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                markerDecoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle), // Nokta rengi
              ),
              headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            ),

            const SizedBox(height: 8.0),
            const Divider(),

            // --- SEÇİLEN GÜNÜN LİSTESİ ---
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: ValueNotifier(_getEventsForDay(_selectedDay!)),
                builder: (context, value, _) {
                  if (value.isEmpty) {
                    return const Center(child: Text("Bu tarihte etkinlik yok."));
                  }
                  
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      var event = value[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          leading: const Icon(Icons.event, color: Colors.indigo),
                          title: Text(event['clubName'] ?? "Kulüp"),
                          subtitle: Text(event['description'] ?? ""),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
    );
  }
}