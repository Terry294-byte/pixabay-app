import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

const String apiKey = 'Pixabay docs on api consumption:https://pixabay.com/api/docs/'; // Replace with your actual Pixabay API key from https://pixabay.com/api/docs/

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
    final url = 'https://pixabay.com/api/?key=$apiKey&q=$query&image_type=photo&per_page=20';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final hits = data['hits'] as List;
      return hits.map((json) => PixabayImage.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load images');
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
      theme: ThemeData(primarySwatch: Colors.blue),
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4.0,
                    mainAxisSpacing: 4.0,
                  ),
                  itemCount: notifier.images.length,
                  itemBuilder: (context, index) {
                    final image = notifier.images[index];
                    return CachedNetworkImage(
                      imageUrl: image.webformatURL,
                      placeholder: (context, url) => const CircularProgressIndicator(),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
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
        const DrawerHeader(
          decoration: BoxDecoration(color: Colors.blue),
          child: Text(
            "Menu",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            decoration: const InputDecoration(
              labelText: 'Search Images',
              border: OutlineInputBorder(),
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
