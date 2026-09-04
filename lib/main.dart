import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  runApp(const SouqApp());
}

class SouqApp extends StatelessWidget {
  const SouqApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'سوق البرامون',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> items = [];
  late BannerAd banner;
  bool bannerReady = false;

  @override
  void initState() {
    super.initState();
    banner = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: (_) => setState(() => bannerReady = true)),
    )..load();
    loadItems();
  }

  loadItems() async {
    final sp = await SharedPreferences.getInstance();
    final s = sp.getString('items');
    if (s!= null) setState(() => items = List<Map<String, dynamic>>.from(jsonDecode(s)));
  }

  saveItems() async {
    final sp = await SharedPreferences.getInstance();
    sp.setString('items', jsonEncode(items));
  }

  addItem() async {
    final picker = ImagePicker();
    final titleCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    XFile? img;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('اضافة اعلان'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'اسم المنتج')),
          TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'السعر'), keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () async { img = await picker.pickImage(source: ImageSource.gallery); }, child: const Text('اختار صورة'))
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('الغاء')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('اضافة')),
        ],
      ),
    );
    if (titleCtrl.text.isNotEmpty) {
      setState(() { items.add({'title': titleCtrl.text, 'price': priceCtrl.text, 'path': img?.path}); });
      saveItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سوق البرامون - 01064788470')),
      body: Column(children: [
        Expanded(
          child: items.isEmpty? const Center(child: Text('لا يوجد اعلانات')) :
          ListView.builder(itemCount: items.length, itemBuilder: (_, i) => Card(
            child: ListTile(
              leading: items[i]['path']!= null? Image.file(File(items[i]['path']), width: 50, height: 50, fit: BoxFit.cover) : const Icon(Icons.store),
              title: Text(items[i]['title']),
              subtitle: Text('${items[i]['price']} جنيه'),
              trailing: IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchUrl(Uri.parse('tel:01064788470'))),
            ),
          )),
        ),
        if (bannerReady) SizedBox(height: 50, child: AdWidget(ad: banner)),
      ]),
      floatingActionButton: FloatingActionButton(onPressed: addItem, child: const Icon(Icons.add)),
    );
  }
}
