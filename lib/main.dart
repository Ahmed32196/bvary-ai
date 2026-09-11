import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const AICreatorApp());

class AICreatorApp extends StatelessWidget {
  const AICreatorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI Creator',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        home: const SplashScreen(),
      );
}

class AppConfig {
  // Public open-source model demo. The app can be pointed to your own Space later.
  static const defaultSpace = 'https://mrfakename-z-image-turbo.hf.space';
  static const defaultApi = '/generate_image';
  static String space = defaultSpace;
  static String api = defaultApi;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    space = p.getString('space') ?? defaultSpace;
    api = p.getString('api') ?? defaultApi;
  }

  static Future<void> save(String newSpace, String newApi) async {
    final p = await SharedPreferences.getInstance();
    space = newSpace.trim().replaceAll(RegExp(r'/$'), '');
    api = newApi.trim().startsWith('/') ? newApi.trim() : '/${newApi.trim()}';
    await p.setString('space', space);
    await p.setString('api', api);
  }
}

class OpenSourceImageClient {
  static Future<Uint8List> generate({
    required String prompt,
    required String ratio,
  }) async {
    final size = _sizeFor(ratio);
    final base = AppConfig.space.replaceAll(RegExp(r'/$'), '');
    final submit = Uri.parse('$base/gradio_api/call${AppConfig.api}');

    final body = jsonEncode({
      'data': [
        prompt,
        size.$2,
        size.$1,
        9,
        DateTime.now().millisecondsSinceEpoch % 4294967295,
        true,
      ]
    });

    final r = await http
        .post(submit, headers: {'Content-Type': 'application/json'}, body: body)
        .timeout(const Duration(seconds: 30));

    if (r.statusCode < 200 || r.statusCode >= 300) {
      throw Exception('تعذر إرسال الطلب (${r.statusCode}).');
    }

    final decoded = jsonDecode(r.body) as Map<String, dynamic>;
    final eventId = decoded['event_id']?.toString();
    if (eventId == null || eventId.isEmpty) {
      throw Exception('المحرك لم يُرجع رقم الطلب.');
    }

    final eventsUrl = Uri.parse('$base/gradio_api/call${AppConfig.api}/$eventId');
    final events = await http.get(eventsUrl).timeout(const Duration(minutes: 3));
    if (events.statusCode < 200 || events.statusCode >= 300) {
      throw Exception('تعذر قراءة نتيجة التوليد (${events.statusCode}).');
    }

    final result = _parseSse(events.body);
    final fileUrl = _extractFileUrl(result, base);
    if (fileUrl == null) {
      throw Exception('المحرك لم يُرجع صورة. جرّب مرة أخرى بعد ثوانٍ.');
    }

    final image = await http.get(Uri.parse(fileUrl)).timeout(const Duration(minutes: 2));
    if (image.statusCode < 200 || image.statusCode >= 300) {
      throw Exception('تعذر تحميل الصورة الناتجة.');
    }
    return image.bodyBytes;
  }

  static dynamic _parseSse(String text) {
    final lines = const LineSplitter().convert(text);
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].trim() == 'event: complete' && i + 1 < lines.length) {
        final dataLine = lines[i + 1];
        if (dataLine.startsWith('data:')) {
          return jsonDecode(dataLine.substring(5).trim());
        }
      }
      if (lines[i].trim() == 'event: error' && i + 1 < lines.length) {
        final dataLine = lines[i + 1];
        if (dataLine.startsWith('data:')) {
          throw Exception(dataLine.substring(5).trim());
        }
      }
    }
    throw Exception('انتهى انتظار المحرك بدون نتيجة.');
  }

  static String? _extractFileUrl(dynamic result, String base) {
    dynamic value = result;
    if (value is List && value.isNotEmpty) value = value.first;
    if (value is List && value.isNotEmpty) value = value.first;
    if (value is Map) {
      value = value['url'] ?? value['path'] ?? value['image'];
    }
    if (value is String && value.isNotEmpty) {
      if (value.startsWith('http://') || value.startsWith('https://')) return value;
      if (value.startsWith('/')) return '$base$value';
      return '$base/$value';
    }
    return null;
  }

  static (int, int) _sizeFor(String ratio) {
    switch (ratio) {
      case '4:5':
        return (896, 1120);
      case '16:9':
        return (1152, 648);
      case '9:16':
        return (648, 1152);
      default:
        return (1024, 1024);
    }
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    AppConfig.load().then((_) {
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.auto_awesome, size: 72),
            SizedBox(height: 18),
            Text('AI Creator', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('ذكاء اصطناعي مفتوح المصدر'),
          ]),
        ),
      );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  void open(BuildContext c, Widget page) => Navigator.push(c, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('AI Creator'), centerTitle: true),
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('أهلاً بيك 👋', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('نسخة تجريبية متصلة بمحرك صور مفتوح المصدر.'),
              const SizedBox(height: 20),
              FeatureCard(icon: Icons.image, title: 'توليد صورة', subtitle: 'اكتب وصف والصورة تتولد فعلياً', onTap: () => open(context, const CreateImageScreen())),
              FeatureCard(icon: Icons.movie_creation, title: 'توليد فيديو', subtitle: 'جاهز للربط بمحركات فيديو مفتوحة المصدر', onTap: () => open(context, const CreateVideoScreen())),
              FeatureCard(icon: Icons.auto_fix_high, title: 'تعديل صورة', subtitle: 'واجهة تجهيز للمرحلة التالية', onTap: () => open(context, const EditImageScreen())),
              FeatureCard(icon: Icons.play_circle, title: 'صورة إلى فيديو', subtitle: 'واجهة تجهيز للمرحلة التالية', onTap: () => open(context, const ImageToVideoScreen())),
              FeatureCard(icon: Icons.photo_library, title: 'أعمالي', subtitle: 'آخر نتيجة محفوظة داخل الجلسة', onTap: () => open(context, const WorksScreen())),
              FeatureCard(icon: Icons.settings, title: 'الإعدادات', subtitle: 'تغيير محرك الذكاء الاصطناعي', onTap: () => open(context, const SettingsScreen())),
            ],
          ),
        ),
      );
}

class FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const FeatureCard({super.key, required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(14),
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_left),
          onTap: onTap,
        ),
      );
}

class CreateImageScreen extends StatefulWidget {
  const CreateImageScreen({super.key});
  @override
  State<CreateImageScreen> createState() => _CreateImageScreenState();
}

class _CreateImageScreenState extends State<CreateImageScreen> {
  final controller = TextEditingController();
  String ratio = '1:1';
  bool loading = false;
  Uint8List? result;

  Future<void> generate() async {
    final prompt = controller.text.trim();
    if (prompt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب وصف للصورة الأول')));
      return;
    }
    setState(() => loading = true);
    try {
      final bytes = await OpenSourceImageClient.generate(prompt: prompt, ratio: ratio);
      if (!mounted) return;
      setState(() => result = bytes);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم توليد الصورة بنجاح ✅')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حصلت مشكلة: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => ToolScaffold(
        title: 'توليد صورة',
        child: ListView(
          children: [
            TextField(
              controller: controller,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'وصف الصورة',
                hintText: 'مثال: شاب مصري واقف في شارع ليلاً بإضاءة سينمائية واقعية، صورة فوتوغرافية عالية التفاصيل',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: ratio,
              decoration: const InputDecoration(labelText: 'نسبة الصورة', border: OutlineInputBorder()),
              items: ['1:1', '4:5', '16:9', '9:16'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => ratio = v ?? '1:1'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: loading ? null : generate,
              icon: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
              label: Text(loading ? 'جاري التوليد… استنى شوية' : 'توليد الصورة مجاناً'),
            ),
            if (result != null) ...[
              const SizedBox(height: 20),
              ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.memory(result!, fit: BoxFit.contain)),
            ],
          ],
        ),
      );
}

class CreateVideoScreen extends StatelessWidget {
  const CreateVideoScreen({super.key});
  @override
  Widget build(BuildContext context) => ToolScaffold(title: 'توليد فيديو', child: _ComingSoon(text: 'هنضيف محرك فيديو مفتوح المصدر بعد تثبيت توليد الصور.'));
}

class EditImageScreen extends StatefulWidget {
  const EditImageScreen({super.key});
  @override
  State<EditImageScreen> createState() => _EditImageScreenState();
}
class _EditImageScreenState extends State<EditImageScreen> {
  XFile? image;
  final prompt = TextEditingController();
  Future<void> pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (p != null) setState(() => image = p);
  }
  @override
  Widget build(BuildContext context) => ToolScaffold(title: 'تعديل صورة', child: ListView(children: [
    if (image != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(image!.path), height: 260, fit: BoxFit.cover)) else _PlaceholderBox(text: 'لم يتم اختيار صورة'),
    const SizedBox(height: 14),
    OutlinedButton.icon(onPressed: pick, icon: const Icon(Icons.upload), label: const Text('اختيار صورة من الهاتف')),
    const SizedBox(height: 14),
    TextField(controller: prompt, maxLines: 4, decoration: const InputDecoration(labelText: 'اكتب التعديل المطلوب', hintText: 'مثال: غيّر الخلفية وحافظ على ملامح الشخص', border: OutlineInputBorder())),
    const SizedBox(height: 14),
    FilledButton(onPressed: image == null ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تعديل الصور هي المرحلة التالية.'))), child: const Text('تنفيذ التعديل')),
  ]));
}

class ImageToVideoScreen extends StatefulWidget {
  const ImageToVideoScreen({super.key});
  @override
  State<ImageToVideoScreen> createState() => _ImageToVideoScreenState();
}
class _ImageToVideoScreenState extends State<ImageToVideoScreen> {
  XFile? image;
  Future<void> pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (p != null) setState(() => image = p);
  }
  @override
  Widget build(BuildContext context) => ToolScaffold(title: 'صورة إلى فيديو', child: ListView(children: [
    if (image != null) ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(image!.path), height: 260, fit: BoxFit.cover)) else _PlaceholderBox(text: 'اختار صورة'),
    const SizedBox(height: 14),
    OutlinedButton.icon(onPressed: pick, icon: const Icon(Icons.photo), label: const Text('اختيار صورة')),
    const SizedBox(height: 14),
    const TextField(maxLines: 4, decoration: InputDecoration(labelText: 'وصف الحركة', hintText: 'مثال: حركة كاميرا بطيئة مع نسيم يحرك الملابس', border: OutlineInputBorder())),
    const SizedBox(height: 14),
    FilledButton(onPressed: image == null ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('محرك Image-to-Video هي المرحلة التالية.'))), child: const Text('إنشاء الفيديو')),
  ]));
}

class WorksScreen extends StatelessWidget {
  const WorksScreen({super.key});
  @override
  Widget build(BuildContext context) => ToolScaffold(title: 'أعمالي', child: const _ComingSoon(text: 'هنضيف معرض محفوظات دائم في المرحلة التالية.'));
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}
class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController space;
  late TextEditingController api;
  @override
  void initState() { super.initState(); space = TextEditingController(text: AppConfig.space); api = TextEditingController(text: AppConfig.api); }
  @override
  void dispose() { space.dispose(); api.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => ToolScaffold(title: 'الإعدادات', child: ListView(children: [
    const Text('محرك الصور المفتوح المصدر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    const Text('الافتراضي يستخدم Hugging Face Space عام. لاحقاً تقدر تحط رابط Space خاص بيك عشان تتحكم في المحرك.'),
    const SizedBox(height: 16),
    TextField(controller: space, decoration: const InputDecoration(labelText: 'رابط Space', border: OutlineInputBorder())),
    const SizedBox(height: 12),
    TextField(controller: api, decoration: const InputDecoration(labelText: 'API endpoint', border: OutlineInputBorder())),
    const SizedBox(height: 16),
    FilledButton.icon(onPressed: () async { await AppConfig.save(space.text, api.text); if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ الإعدادات ✅'))); }, icon: const Icon(Icons.save), label: const Text('حفظ')),
    const SizedBox(height: 24),
    const ListTile(leading: Icon(Icons.info_outline), title: Text('مهم'), subtitle: Text('مجاني لا يعني بلا حدود: ZeroGPU له حصص يومية حسب الحساب. التطبيق مصمم بحيث نقدر نبدّل المحرك لاحقاً بدون تغيير الواجهة.')),
  ]));
}

class ToolScaffold extends StatelessWidget {
  final String title; final Widget child;
  const ToolScaffold({super.key, required this.title, required this.child});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text(title)), body: Directionality(textDirection: TextDirection.rtl, child: Padding(padding: const EdgeInsets.all(16), child: child)));
}

class _PlaceholderBox extends StatelessWidget {
  final String text; const _PlaceholderBox({required this.text});
  @override
  Widget build(BuildContext context) => Container(height: 220, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)), child: Text(text));
}
class _ComingSoon extends StatelessWidget {
  final String text; const _ComingSoon({required this.text});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.construction, size: 70), const SizedBox(height: 16), Text(text, textAlign: TextAlign.center)]));
}
