import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/my_user_tile.dart';
import '../models/user.dart';
import '../services/database/database_provider.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // providers
  late final databaseProvider =
  Provider.of<DatabaseProvider>(context, listen: false);
  late final listeningProvider = Provider.of<DatabaseProvider>(context);


  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (value.trim().isNotEmpty) {
        setState(() {
          _isSearching = true;
          _hasSearched = true;
        });

        await databaseProvider.searchUsers(value.trim());

        setState(() {
          _isSearching = false;
        });
      } else {
        databaseProvider.clearSearchResults();
        setState(() {
          _isSearching = false;
          _hasSearched = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Container(
          height: 38,
          decoration: BoxDecoration(
            color: colorScheme.secondary,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            children: [
              const SizedBox(width: 10),

              // Search icon
              Icon(Icons.search, color: colorScheme.primary.withOpacity(0.7)),

              const SizedBox(width: 6),

              // Text field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: colorScheme.primary),
                  cursorColor: colorScheme.primary,
                  decoration: InputDecoration(
                    hintText: "Search",
                    hintStyle: TextStyle(
                      color: colorScheme.primary.withOpacity(0.6),
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    _onSearchChanged(value);
                    setState(() {}); // refresh to toggle back button visibility
                  },
                ),
              ),

              // Clear button (only visible if text not empty)
              if (_searchController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    listeningProvider.clearSearchResults();
                    setState(() {
                      _hasSearched = false;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(Icons.close,
                        color: colorScheme.primary.withOpacity(0.6), size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: _isSearching
          ? Center(
        child: Text(
          "Searching...",
          style: TextStyle(color: colorScheme.primary),
        ),
      )
          : (_hasSearched && listeningProvider.searchResults.isEmpty)
          ? Center(
        child: Text(
          "No users found...",
          style: TextStyle(color: colorScheme.primary),
        ),
      )
          : ListView.builder(
        itemCount: listeningProvider.searchResults.length,
        itemBuilder: (context, index) {
          final UserProfile user =
          listeningProvider.searchResults[index];
          return MyUserTile(
            user: user,
            customTitle: user.name,
          );
        },
      ),
    );
  }
}
