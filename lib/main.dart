import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

const String apiKey = '52558185-f16088b1e079a8ba98e7a1089'; // Replace with your actual Pixabay API key from https://pixabay.com/api/docs/

class PixabayImage {
  final String id;
  final String pageURL;
  final String type;
  final String tags;
  final String previewURL;
  final String webformatURL;
  final String largeImageURL;
  final int views;
  final int downloads;
  final int likes;
  final int comments;
  final int user_id;
  final String user;
  final String userImageURL;

  PixabayImage({
    required this.id,
    required this.pageURL,
    required this.type,
    required this.tags,
    required this.previewURL,
    required this.webformatURL,
    required this.largeImageURL,
    required this.views,
    required this.downloads,
    required this.likes,
    required this.comments,
    required this.user_id,
    required this.user,
    required this.userImageURL,
  });

  factory PixabayImage.fromJson(Map<String, dynamic> json) {
    return PixabayImage(
      id: json['id'].toString(),
      pageURL: json['pageURL'],
      type: json['type'],
      tags: json['tags'],
      previewURL: json['previewURL'],
      webformatURL: json['webformatURL'],
      largeImageURL: json['largeImageURL'],
      views: json['views'],
      downloads: json['downloads'],
      likes: json['likes'],
      comments: json['comments'],
      user_id: json['user_id'],
      user: json['user'],
      userImageURL: json['userImageURL'],
    );
  }
}

class PixabayService {
  static Future<List<PixabayImage>> fetchImages(String query) async {
    final url = 'https://pixabay.com/api/?key=52558185-f16088b1e079a8ba98e7a1089&q=nature&image_type=photo';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final hits = data['hits'] as List;
      return hits.map((json) => PixabayImage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load images: ${response.statusCode} ${response.reasonPhrase}');
    }
  }
}

class ImageNotifier extends ChangeNotifier {
  List<PixabayImage> _images = [];
  bool _isLoading = false;
  String _error = '';

  List<PixabayImage> get images => _images;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchImages(String query) async {
    _isLoading = true;
    _error = '';
    notifyListeners();
    try {
      _images = await PixabayService.fetchImages(query);
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }
}

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ImageNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pixabay Dashboard',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const ResponsiveDashboard(),
    );
  }
}

class ResponsiveDashboard extends StatefulWidget {
  const ResponsiveDashboard({super.key});

  @override
  State<ResponsiveDashboard> createState() => _ResponsiveDashboardState();
}

class _ResponsiveDashboardState extends State<ResponsiveDashboard> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch default images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ImageNotifier>().fetchImages('nature');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pixabay Dashboard"),
      ),
      body: Row(
        children: [
          if (isWideScreen)
            Container(
              width: 200,
              color: Colors.blue[50],
              child: SidebarMenu(searchController: _searchController),
            ),
          Expanded(
            child: Consumer<ImageNotifier>(
              builder: (context, notifier, child) {
                if (notifier.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (notifier.error.isNotEmpty) {
                  return Center(child: Text('Error: ${notifier.error}'));
                }
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: notifier.images.length,
                  itemBuilder: (context, index) {
                    final image = notifier.images[index];
                    return GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            contentPadding: EdgeInsets.zero,
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.network(image.largeImageURL),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    image.tags,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Likes: ${image.likes}'),
                                      Text('Views: ${image.views}'),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('User: ${image.user}'),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CachedNetworkImage(
                                imageUrl: image.webformatURL,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      image.tags,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.thumb_up, size: 12, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Text('${image.likes}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            const Icon(Icons.visibility, size: 12, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Text('${image.views}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      drawer: isWideScreen ? null : Drawer(child: SidebarMenu(searchController: _searchController)),
    );
  }
}

class SidebarMenu extends StatelessWidget {
  final TextEditingController searchController;

  const SidebarMenu({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Removed DrawerHeader to eliminate blue part
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search Images',
              border: OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
            ),
            onSubmitted: (query) {
              if (query.isNotEmpty) {
                context.read<ImageNotifier>().fetchImages(query);
              }
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.home),
          title: const Text("Dashboard"),
          onTap: () {
            // Already on dashboard
          },
        ),
        ListTile(
          leading: const Icon(Icons.image),
          title: const Text("Images"),
          onTap: () {
            // Already showing images
          },
        ),
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text("Settings"),
        ),
      ],
    );
  }
}
