import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crowdease/core/api_constants.dart';

class UserPreferencesScreen extends StatefulWidget {
  final String userId;
  const UserPreferencesScreen({super.key, required this.userId});

  @override
  State<UserPreferencesScreen> createState() => _UserPreferencesScreenState();
}

class _UserPreferencesScreenState extends State<UserPreferencesScreen> {
  List<String> availableRoutes = [];
  List<String> filteredRoutes = [];
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
    print("Fetching available routes...");print(ApiConstants.baseUrl);
    final response = await http.get(Uri.parse('${ApiConstants.baseUrl}/dropdown/routes'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        availableRoutes = List<String>.from(
          data is List ? data : data.map<String>((r) => r["route"]).toList(),
        );
        filteredRoutes = availableRoutes;
        isRouteLoading = false;
      });
      print("Routes loaded: ${availableRoutes.length}");
    } else {
      print("Failed to load routes: ${response.body}");
      setState(() => isRouteLoading = false);
    }
  }

  Future<void> fetchSavedPreferences() async {
    print("Fetching preferences for user: $normalizedUserId");
    final response = await http.get(
      Uri.parse("${ApiConstants.baseUrl}/get-preferences/$normalizedUserId"),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        selectedFavorites = List<String>.from(data["favorite_routes"]);
        selectedRegular = data["regular_route"];
        hasSavedPreferences = true;
        isPrefLoading = false;
      });
      print("Loaded existing preferences.");
    } else {
      print("No saved preferences found.");
      setState(() {
        hasSavedPreferences = false;
        isPrefLoading = false;
      });
    }
  }

  Future<void> savePreferences() async {
    if (selectedFavorites.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 5 favorite routes allowed")),
      );
      return;
    }

    final body = json.encode({
      "user_id": normalizedUserId,
      "favorite_routes": selectedFavorites,
      "regular_route": selectedRegular,
    });

    final url = Uri.parse(
      hasSavedPreferences
          ? "${ApiConstants.baseUrl}/update-preferences"
          : "${ApiConstants.baseUrl}/save-preferences",
    );
    final method = hasSavedPreferences ? http.put : http.post;

    print("Saving preferences using ${hasSavedPreferences ? "PUT" : "POST"} to $url");
    print("Request body: $body");

    final response = await method(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    print("Response status: ${response.statusCode}, body: ${response.body}");

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preferences saved successfully!")),
      );
      Future.delayed(const Duration(seconds: 1), () => Navigator.pop(context));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving preferences: ${response.body}")),
      );
    }
  }

  Future<void> deletePreferences() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Deletion"),
        content: const Text("Are you sure you want to delete all preferences?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    );

    if (confirm != true) return;

    print("Deleting preferences for user: $normalizedUserId");
    final response = await http.delete(
      Uri.parse("${ApiConstants.baseUrl}/remove-preferences/$normalizedUserId"),
    );

    print("Delete response: ${response.statusCode}, body: ${response.body}");

    if (response.statusCode == 200) {
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
      filteredRoutes = availableRoutes
          .where((route) => route.toLowerCase().contains(query.toLowerCase()))
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
                final route = filteredRoutes[index];
                final isSelected = selectedItems.contains(route);
                final highlightStyle = TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.deepPurple : null,
                );

                if (isRadio) {
                  return RadioListTile<String>(
                    title: Text(route, style: highlightStyle),
                    value: route,
                    groupValue: selectedRegular,
                    onChanged: (value) {
                      setState(() {
                        selectedRegular = value;
                      });
                    },
                  );
                } else {
                  return CheckboxListTile(
                    title: Text(route, style: highlightStyle),
                    value: isSelected,
                    onChanged: (bool? selected) {
                      setState(() {
                        if (selected == true && !isSelected && selectedItems.length < maxSelection) {
                          onItemChanged(route, true);
                        } else if (selected == false) {
                          onItemChanged(route, false);
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
    final isReadyToSave = !isLoading && selectedRegular != null && selectedFavorites.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text("Select Your Preferred Routes")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Favorite Routes (Max 5)", style: TextStyle(fontWeight: FontWeight.bold)),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Regular Route", style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          buildSearchableList(
                            selectedItems: selectedRegular != null ? [selectedRegular!] : [],
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
                    color: Colors.grey.shade100,
                    child: ListTile(
                      title: const Text("Your Selected Preferences"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Favorites: ${selectedFavorites.join(', ')}"),
                          Text("Regular: ${selectedRegular ?? 'Not selected'}"),
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
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: deletePreferences,
                        icon: const Icon(Icons.delete),
                        label: const Text("Delete All"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade400,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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
