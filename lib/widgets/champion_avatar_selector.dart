import 'package:flutter/material.dart';
import '../services/league_of_legends_service.dart';
import '../utils/app_colors.dart';

class ChampionAvatarSelector extends StatefulWidget {
  final String? currentAvatarUrl;
  final Function(String) onAvatarSelected;

  const ChampionAvatarSelector({
    super.key,
    this.currentAvatarUrl,
    required this.onAvatarSelected,
  });

  @override
  State<ChampionAvatarSelector> createState() => _ChampionAvatarSelectorState();
}

class _ChampionAvatarSelectorState extends State<ChampionAvatarSelector> {
  final TextEditingController _searchController = TextEditingController();
  List<Champion> _allChampions = [];
  List<Champion> _filteredChampions = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChampions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChampions() async {
    try {
      final champions = await LeagueOfLegendsService.instance.getAllChampions();
      setState(() {
        _allChampions = champions;
        _filteredChampions = champions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterChampions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredChampions = _allChampions;
      } else {
        _filteredChampions = _allChampions
            .where((champion) =>
                champion.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Título
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Elige tu campeón',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar campeón...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterChampions,
            ),
            const SizedBox(height: 16),

            // Grid de campeones
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildPopularChampions()
                      : _filteredChampions.isEmpty
                          ? const Center(
                              child: Text('No se encontraron campeones'))
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: _filteredChampions.length,
                              itemBuilder: (context, index) {
                                final champion = _filteredChampions[index];
                                return _buildChampionTile(
                                  champion.imageUrl,
                                  champion.name,
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularChampions() {
    final popularChampions = LeagueOfLegendsService.getPopularChampions();
    return Column(
      children: [
        const Text(
          'Campeones populares',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: popularChampions.length,
            itemBuilder: (context, index) {
              final champion = popularChampions[index];
              return _buildChampionTile(
                champion.imageUrl,
                champion.name,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChampionTile(String imageUrl, String name) {
    final isSelected = widget.currentAvatarUrl == imageUrl;
    
    return GestureDetector(
      onTap: () {
        widget.onAvatarSelected(imageUrl);
        Navigator.pop(context);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: ClipOval(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, color: Colors.grey),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 14,
            child: Text(
              name,
              style: const TextStyle(fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

