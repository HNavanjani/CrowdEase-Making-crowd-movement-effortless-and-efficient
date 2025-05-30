import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/route_data.dart';
import '../../../core/http_helper.dart';

class UserPreferencesScreen extends StatefulWidget {
  final String userId;
  const UserPreferencesScreen({super.key, required this.userId});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  List<String> availableRoutes = [];
  List<String> filteredRoutes = [];
  List<RouteData> structuredRoutes = [];
  List<String> selectedFavorites = [];
  String? selectedRegular;
  bool isRouteLoading = true;
  bool isPrefLoading = true;
  String searchQuery = "";
  bool hasSavedPreferences = false;
  late String normalizedUserId;

  @override
  void initState() {
    super.initState();
    normalizedUserId = widget.userId.trim();
    fetchAvailableRoutes();
    fetchSavedPreferences();
  }

  Future<void> fetchAvailableRoutes() async {
    final data = await HttpHelper.get('/dropdown/routes');
    if (data != null) {
      final routes = (data as List).map((e) => RouteData.fromJson(e)).toList();
      setState(() {
        structuredRoutes = routes;
        availableRoutes = routes.map((r) => r.routeId).toList();
        filteredRoutes = availableRoutes;
        isRouteLoading = false;
      });
    } else {
      setState(() => isRouteLoading = false);
    }
  }

  Future<void> fetchSavedPreferences() async {
    final data = await HttpHelper.get("/get-preferences/$normalizedUserId");
    if (data != null) {
      setState(() {
        selectedFavorites = List<String>.from(data["favorite_routes"]);
        selectedRegular = data["regular_route"];
        hasSavedPreferences = true;
        isPrefLoading = false;
      });
    } else {
      setState(() {
        hasSavedPreferences = false;
        isPrefLoading = false;
      });
    }
  }

  Future<void> savePreferences() async {
    if (selectedFavorites.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Maximum 5 favorite routes allowed.\nTip: Search by route number or name, then tick to select.",
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final body = {
      "user_id": normalizedUserId,
      "favorite_routes": selectedFavorites,
      "regular_route": selectedRegular,
    };

    final endpoint =
        hasSavedPreferences ? "/update-preferences" : "/save-preferences";

    final response =
        hasSavedPreferences
            ? await HttpHelper.put(endpoint, body)
            : await HttpHelper.post(endpoint, body);

    if (response != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preferences saved successfully!")),
      );
      Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Error saving preferences")));
    }
  }

  Future<void> deletePreferences() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: const Text(
              "Are you sure you want to delete all preferences?",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Delete"),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final response = await HttpHelper.delete(
      "/remove-preferences/$normalizedUserId",
    );

    if (response != null) {
      setState(() {
        selectedFavorites.clear();
        selectedRegular = null;
        hasSavedPreferences = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preferences deleted successfully")),
      );
      Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error deleting preferences")),
      );
    }
  }

  void updateFilteredRoutes(String query) {
    setState(() {
      searchQuery = query;
      filteredRoutes =
          structuredRoutes
              .where(
                (r) =>
                    r.shortName.toLowerCase().contains(query.toLowerCase()) ||
                    r.longName.toLowerCase().contains(query.toLowerCase()),
              )
              .map((r) => r.routeId)
              .toList();
    });
  }

  Widget buildSearchableList({
    required List<String> selectedItems,
    required Function(String, bool) onItemChanged,
    required int maxSelection,
    bool isRadio = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: const InputDecoration(
            hintText: "Search routes...",
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: updateFilteredRoutes,
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: Scrollbar(
            child: ListView.builder(
              itemCount: filteredRoutes.length,
              itemBuilder: (context, index) {
                final routeId = filteredRoutes[index];
                final isSelected = selectedItems.contains(routeId);
                final routeObj = structuredRoutes.firstWhere(
                  (r) => r.routeId == routeId,
                  orElse:
                      () => RouteData(
                        routeId: routeId,
                        shortName: routeId,
                        longName: '',
                        desc: '',
                      ),
                );
                final routeLabel =
                    '${routeObj.shortName} – ${routeObj.longName}';

                final highlightStyle = TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.deepPurple : null,
                );

                if (isRadio) {
                  return RadioListTile<String>(
                    title: Text(routeLabel, style: highlightStyle),
                    value: routeId,
                    groupValue: selectedRegular,
                    onChanged:
                        (value) => setState(() => selectedRegular = value),
                  );
                } else {
                  return CheckboxListTile(
                    title: Text(routeLabel, style: highlightStyle),
                    value: isSelected,
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true &&
                            !isSelected &&
                            selectedItems.length < maxSelection) {
                          onItemChanged(routeId, true);
                        } else if (selected == false) {
                          onItemChanged(routeId, false);
                        }
                      });
                    },
                  );
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = isRouteLoading || isPrefLoading;
    final isReadyToSave =
        !isLoading && selectedRegular != null && selectedFavorites.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Preferred Routes")),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 18,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              "Tip: You can search by route number or bus name, then tick to select favorites and pick a regular route.",
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Favorite Routes (Max 5)",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            buildSearchableList(
                              selectedItems: selectedFavorites,
                              onItemChanged: (route, selected) {
                                if (selected) {
                                  selectedFavorites.add(route);
                                } else {
                                  selectedFavorites.remove(route);
                                }
                              },
                              maxSelection: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Regular Route",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            buildSearchableList(
                              selectedItems:
                                  selectedRegular != null
                                      ? [selectedRegular!]
                                      : [],
                              onItemChanged: (route, selected) {
                                selectedRegular = selected ? route : null;
                              },
                              maxSelection: 1,
                              isRadio: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      color: Theme.of(context).colorScheme.surface,
                      child: ListTile(
                        title: const Text("Your Selected Preferences"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Favorites: ${selectedFavorites.map((id) {
                                final r = structuredRoutes.firstWhere((e) => e.routeId == id, orElse: () => RouteData(routeId: id, shortName: id, longName: '', desc: ''));
                                return '${r.shortName} – ${r.longName}';
                              }).join(', ')}",
                            ),
                            Text(
                              "Regular: ${selectedRegular != null ? (() {
                                    final r = structuredRoutes.firstWhere((e) => e.routeId == selectedRegular, orElse: () => RouteData(routeId: selectedRegular!, shortName: selectedRegular!, longName: '', desc: ''));
                                    return '${r.shortName} – ${r.longName}';
                                  })() : 'Not selected'}",
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isReadyToSave ? savePreferences : null,
                          icon: const Icon(Icons.save),
                          label: const Text("Save Preferences"),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: deletePreferences,
                          icon: const Icon(Icons.delete),
                          label: const Text("Delete All"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}
