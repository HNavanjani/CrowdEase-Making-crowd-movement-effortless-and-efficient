import 'package:flutter/material.dart';
import '../../../core/http_helper.dart';

class AlertsAndNotificationsScreen extends StatefulWidget {
  const AlertsAndNotificationsScreen({super.key});

  @override
  State<AlertsAndNotificationsScreen> createState() =>
      _AlertsAndNotificationsScreenState();
}

class _AlertsAndNotificationsScreenState extends State<AlertsAndNotificationsScreen> {
  List<Map<String, dynamic>> alerts = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchAlerts();
  }

  Future<void> fetchAlerts() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final response = await HttpHelper.get('/alerts');
    final alertList = response?['alerts'];

    if (alertList == null || alertList is! List) {
      setState(() {
        error = "No alerts found or invalid response.";
        isLoading = false;
      });
      return;
    }

    setState(() {
      alerts = List<Map<String, dynamic>>.from(alertList)
          .map((alert) => {...alert, 'expanded': false})
          .toList();
      isLoading = false;
    });
  }

  IconData _getAlertIcon(String content) {
    final lower = content.toLowerCase();
    if (lower.contains('divert') || lower.contains('detour')) return Icons.route;
    if (lower.contains('closure') || lower.contains('closed')) return Icons.block;
    if (lower.contains('delay') || lower.contains('disrupt')) return Icons.warning_amber;
    return Icons.info_outline;
  }

  Color _getAlertColor(String content, BuildContext context) {
    final lower = content.toLowerCase();
    if (lower.contains('divert') || lower.contains('detour')) return Colors.orange;
    if (lower.contains('closure') || lower.contains('closed')) return Colors.red;
    if (lower.contains('delay') || lower.contains('disrupt')) return Colors.amber;
    return Theme.of(context).colorScheme.primary;
  }

  Widget buildAlertCard(Map<String, dynamic> alert, int index) {
    final title = alert['title'] ?? 'Alert';
    final message = alert['message'] ?? '';
    final routes = (alert['routes'] as List?)?.join(', ') ?? '';
    final isExpanded = alert['expanded'] ?? false;

    final icon = _getAlertIcon(title + message);
    final color = _getAlertColor(title + message, context);
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: theme.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            alerts[index]['expanded'] = !isExpanded;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (routes.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.directions_bus, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      "Routes: $routes",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              AnimatedCrossFade(
                firstChild: Text(
                  message,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                secondChild: Text(
                  message,
                  style: theme.textTheme.bodyMedium,
                ),
                crossFadeState: isExpanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
              if (message.length > 120)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        alerts[index]['expanded'] = !isExpanded;
                      });
                    },
                    child: Text(isExpanded ? "Show less" : "Show more"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Alerts"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchAlerts,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Text(
                    error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                )
              : alerts.isEmpty
                  ? const Center(child: Text("No current alerts"))
                  : RefreshIndicator(
                      onRefresh: fetchAlerts,
                      child: ListView.builder(
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          return buildAlertCard(alerts[index], index);
                        },
                      ),
                    ),
    );
  }
}
