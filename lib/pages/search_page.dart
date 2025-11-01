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
    final databaseProvider = Provider.of<DatabaseProvider>(context, listen: false);

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
    final databaseProvider = Provider.of<DatabaseProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: (_searchController.text.isNotEmpty || _hasSearched)
            ? IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary),
          onPressed: () {
            _searchController.clear();
            databaseProvider.clearSearchResults();
            setState(() {
              _hasSearched = false;
            });
          },
        )
            : null,
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
          decoration: InputDecoration(
            hintText: "Search users...",
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            _onSearchChanged(value);
            setState(() {}); // refresh to toggle back button visibility
          },
        ),
      ),
      body: _isSearching
          ? Center(
        child: Text(
          "Searching...",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      )
          : (_hasSearched && databaseProvider.searchResults.isEmpty)
          ? Center(
        child: Text(
          "No users found...",
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
      )
          : ListView.builder(
        itemCount: databaseProvider.searchResults.length,
        itemBuilder: (context, index) {
          final UserProfile user = databaseProvider.searchResults[index];
          return MyUserTile(
            user: user,
            customTitle: user.name,
          );
        },
      ),
    );
  }
}
