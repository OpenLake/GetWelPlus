import 'package:flutter/material.dart';
import 'package:flutter_app/core/error_messages.dart';
import 'package:flutter_app/pages/article_reader_page.dart';
import 'package:flutter_app/services/article_service.dart';
import 'package:flutter_app/widgets/article_card.dart';

class ArticlesPage extends StatefulWidget {
  const ArticlesPage({super.key});

  @override
  State<ArticlesPage> createState() => _ArticlesPageState();
}

class _ArticlesPageState extends State<ArticlesPage> {
  int selectedCategoryIndex = 0;
  final ArticleService _articleService = ArticleService();

  // cached articles to avoid refetching
  List<Article> _popularArticles = [];
  Map<String, List<Article>> _categoryArticles = {};
  
  // loading and error states
  bool _loadingPopular = true;
  bool _loadingCategory = true;
  String? _popularError;
  String? _categoryError;

  final List<String> categories = [
    "Meditation",
    "Anxiety",
    "Stress",
    "Sleep",
    "Self Growth",
  ];

  @override
  void initState() {
    super.initState();
    _loadPopularArticles();
    _loadCategoryArticles(categories[0]);
  }

  Future<void> _loadPopularArticles() async {
    setState(() {
      _loadingPopular = true;
      _popularError = null;
    });

    try {
      final articles = await _articleService.fetchPopularArticles(pageSize: 8);
      if (mounted) {
        setState(() {
          _popularArticles = articles;
          _loadingPopular = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _popularError = friendlyErrorMessage(e);
          _loadingPopular = false;
        });
      }
    }
  }

  Future<void> _loadCategoryArticles(String category) async {
    // check cache first
    if (_categoryArticles.containsKey(category)) {
      setState(() => _loadingCategory = false);
      return;
    }

    setState(() {
      _loadingCategory = true;
      _categoryError = null;
    });

    try {
      final articles = await _articleService.fetchArticles(
        category: category,
        pageSize: 15,
      );
      if (mounted) {
        setState(() {
          _categoryArticles[category] = articles;
          _loadingCategory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _categoryError = friendlyErrorMessage(e);
          _loadingCategory = false;
        });
      }
    }
  }

  void _onCategoryTap(int index) {
    if (index == selectedCategoryIndex) return;
    setState(() => selectedCategoryIndex = index);
    _loadCategoryArticles(categories[index]);
  }

  void _openArticle(Article article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArticleReaderPage(article: article),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currentCategory = categories[selectedCategoryIndex];
    final categoryList = _categoryArticles[currentCategory] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Articles",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadPopularArticles();
          _categoryArticles.clear(); // clear cache
          await _loadCategoryArticles(currentCategory);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // popular section
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Popular",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // popular articles carousel
              if (_loadingPopular)
                const SizedBox(
                  height: 280,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_popularError != null)
                _buildErrorWidget(_popularError!, _loadPopularArticles)
              else if (_popularArticles.isEmpty)
                _buildEmptyWidget('No popular articles found')
              else
                SizedBox(
                  height: 290,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _popularArticles.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final article = _popularArticles[index];
                      return ArticleCard(
                        imageUrl: article.imageUrl,
                        title: article.title,
                        subtitle: article.description,
                        source: article.source,
                        timeAgo: article.formattedDate,
                        onTap: () => _openArticle(article),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 24),

              // topics section
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Topics",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // category chips
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final isSelected = selectedCategoryIndex == index;

                    return GestureDetector(
                        onTap: () => _onCategoryTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isSelected
                                ? scheme.primary
                                : scheme.surfaceContainerHighest,
                          ),
                          child: Text(
                            categories[index],
                            style: TextStyle(
                              color: isSelected
                                  ? scheme.onPrimary
                                  : scheme.onSurface,
                              fontWeight:
                                  isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 16),

              // category articles list
              if (_loadingCategory)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_categoryError != null)
                _buildErrorWidget(_categoryError!, () => _loadCategoryArticles(currentCategory))
              else if (categoryList.isEmpty)
                _buildEmptyWidget('No articles found for $currentCategory')
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: categoryList.map((article) {
                      return _ArticleListTile(
                        article: article,
                        onTap: () => _openArticle(article),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message, VoidCallback onRetry) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.article_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// list tile for category articles - compact vertical layout
class _ArticleListTile extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const _ArticleListTile({required this.article, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: scheme.outlineVariant.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                // thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 90,
                    height: 90,
                    child: article.imageUrl != null
                        ? Image.network(
                            article.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(scheme),
                          )
                        : _placeholder(scheme),
                  ),
                ),

                const SizedBox(width: 14),

                // text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // source and time
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              article.source,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            article.formattedDate,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: scheme.outline,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      // title
                      Text(
                        article.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // description snippet
                      Text(
                        article.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(ColorScheme scheme) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.article_rounded,
          color: scheme.outline,
        ),
      ),
    );
  }
}
