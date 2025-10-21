import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../models/user.dart';
import '../models/post.dart';
import '../services/firestore_service.dart';
import '../utils/app_colors.dart';
import '../widgets/user_card.dart';
import '../widgets/post_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService.instance;
  late TabController _tabController;
  
  List<User> _users = [];
  List<Post> _posts = [];
  bool _isSearching = false;
  String _currentFilter = 'all'; // all, users, posts

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _users = [];
        _posts = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final users = await _firestoreService.searchUsers(query);
      final posts = await _firestoreService.searchPosts(query);

      setState(() {
        _users = users;
        _posts = posts;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en búsqueda: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Buscar usuarios, publicaciones, #hashtags...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.6),
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'Todo (${_users.length + _posts.length})'),
            Tab(text: 'Usuarios (${_users.length})'),
            Tab(text: 'Posts (${_posts.length})'),
          ],
        ),
      ),
      body: _isSearching
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAllTab(),
                _buildUsersTab(),
                _buildPostsTab(),
              ],
            ),
    );
  }

  Widget _buildAllTab() {
    if (_users.isEmpty && _posts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView(
      children: [
        if (_users.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Usuarios',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._users.map((user) => UserCard(
                user: user,
                onTap: () {
                  if (user.id != null) {
                    context.push('/profile/${user.id}');
                  }
                },
              )),
        ],
        if (_posts.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Publicaciones',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._posts.map((post) => PostCard(post: post)),
        ],
      ],
    );
  }

  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        return UserCard(
          user: user,
          onTap: () {
            if (user.id != null) {
              context.push('/profile/${user.id}');
            }
          },
        );
      },
    );
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        return PostCard(post: _posts[index]);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'Busca usuarios, publicaciones o #hashtags'
                : 'No se encontraron resultados',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

