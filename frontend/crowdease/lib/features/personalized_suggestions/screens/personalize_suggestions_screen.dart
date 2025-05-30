import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/http_helper.dart';

class PersonalizedSuggestionsScreen extends StatefulWidget {
  const PersonalizedSuggestionsScreen({super.key});

  @override
  State<PersonalizedSuggestionsScreen> createState() => _PersonalizedSuggestionsScreenState();
}

class _PersonalizedSuggestionsScreenState extends State<PersonalizedSuggestionsScreen> {
  final List<String> purposes = ['Work', 'Home', 'Other'];
  final List<String> days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  final List<String> timeBands = List.generate(24, (i) => '${i.toString().padLeft(2, '0')}:00 to ${(i + 1).toString().padLeft(2, '0')}:00');

  String selectedPurpose = 'Work';
  String selectedDay = 'Monday';
  String selectedTime = '08:00 to 09:00';

  Map<String, dynamic> timeBandData = {};
  String suggestionMessage = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchForecastData();
  }

  Future<void> fetchForecastData() async {
    setState(() => isLoading = true);
    final response = await HttpHelper.get('/forecast/weekly');
    if (response != null && response['time_band_forecast'] != null) {
      setState(() {
        timeBandData = Map<String, dynamic>.from(response['time_band_forecast']);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  void generateSuggestion() {
    final dayData = Map<String, dynamic>.from(timeBandData[selectedDay] ?? {});
    final value = (dayData[selectedTime] as num?)?.toDouble();

    if (value == null) {
      setState(() => suggestionMessage = 'No data available for $selectedDay at $selectedTime.');
      return;
    }

    String levelText = value < 0.04
        ? 'Low crowding'
        : value < 0.07
            ? 'Moderate crowding'
            : 'High crowding';

    String contextMessage = value < 0.04
        ? "✅ This is one of the least crowded times on $selectedDay.\n📉 Expect a smooth and quick commute."
        : value < 0.07
            ? "🟠 Moderate crowd — you may experience some delay.\n🚶 Consider leaving earlier for comfort."
            : "🔴 High crowding expected.\n😣 You may face delays or discomfort during travel.";

    final sorted = dayData.entries.toList()
      ..sort((a, b) => (a.value as double).compareTo(b.value as double));
    final betterSlot = sorted.firstWhere(
      (e) => (e.value as double) < value && e.key != selectedTime,
      orElse: () => MapEntry('', 0.0),
    );

    String tip = '';
    if (betterSlot.key.isNotEmpty) {
      tip = "💡 Tip: If you're flexible, ${betterSlot.key} has even lower crowding.";
    }

    setState(() {
      suggestionMessage =
          "When you leave for $selectedPurpose on $selectedDay at $selectedTime:\n"
          "→ Crowd Level: ($levelText)\n\n"
          "$contextMessage\n\n"
          "$tip";
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalized Suggestions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchForecastData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Where are you going?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedPurpose,
                    decoration: InputDecoration(border: OutlineInputBorder(), filled: true),
                    items: purposes.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                    onChanged: (val) => setState(() => selectedPurpose = val!),
                  ),
                  const SizedBox(height: 16),

                  const Text('Which day?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: InputDecoration(border: OutlineInputBorder(), filled: true),
                    items: days.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) => setState(() => selectedDay = val!),
                  ),
                  const SizedBox(height: 16),

                  const Text('Preferred time?', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedTime,
                    decoration: InputDecoration(border: OutlineInputBorder(), filled: true),
                    items: timeBands.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => selectedTime = val!),
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: generateSuggestion,
                    icon: const Icon(Icons.lightbulb_outline),
                    label: const Text("Get My Travel Suggestion"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.deepPurple.shade300 : Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (suggestionMessage.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                      ),
                      child: Text(
                        suggestionMessage,
                        style: const TextStyle(height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
