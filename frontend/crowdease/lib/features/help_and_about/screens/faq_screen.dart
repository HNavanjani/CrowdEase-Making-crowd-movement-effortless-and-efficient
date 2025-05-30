import 'package:flutter/material.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = [
      {
        "q": "How are crowd levels predicted?",
        "a": "We use machine learning models trained on historical data and user feedback."
      },
      {
        "q": "How often is the data updated?",
        "a": "Every 30 seconds, we check for new model predictions."
      },
      {
        "q": "Can I change my route preferences?",
        "a": "Yes! Use the Route Preferences option in the drawer menu."
      },
      {
        "q": "Why does a route show 'Unavailable'?",
        "a": "This usually happens when no data is available for that time slot."
      },
      {
        "q": "Is this data from TfNSW?",
        "a": "Yes, we use TfNSW open GTFS datasets from 2016–17."
      },
      {
        "q": "Can I use this offline?",
        "a": "No. A stable internet connection is required for accurate predictions."
      },
      {
        "q": "Does CrowdEase track my location?",
        "a": "No. Your location is not collected or stored in any way."
      },
      {
        "q": "How can I report a bug or suggestion?",
        "a": "Send an email to crowdeaseofficial@gmail.com."
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('FAQs')),
      body: ListView.builder(
        itemCount: faqs.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final item = faqs[index];
          return ListTile(
            leading: const Icon(Icons.question_answer_outlined),
            title: Text("Q: ${item['q']}"),
            subtitle: Text("A: ${item['a']}"),
          );
        },
      ),
    );
  }
}
