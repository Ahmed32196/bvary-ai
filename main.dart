import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() => runApp(const AICreatorApp());

class AICreatorApp extends StatelessWidget {
  const AICreatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Creator',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'sans',
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: const SplashScreen(),
    );
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
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: const [
        Icon(Icons.auto_awesome, size: 72),
        SizedBox(height: 18),
        Text('AI Creator', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        Text('صانع المحتوى بالذكاء الاصطناعي'),
      ]),
    ),
  );
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void open(BuildContext c, Widget page) =>
      Navigator.push(c, MaterialPageRoute(builder: (_) => page));

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
          const Text('اختار الأداة اللي عايز تستخدمها'),
          const SizedBox(height: 20),
          FeatureCard(
            icon: Icons.image,
            title: 'توليد صورة',
            subtitle: 'اكتب وصف والصورة تتجهز',
            onTap: () => open(context, const CreateImageScreen()),
          ),
          FeatureCard(
            icon: Icons.movie_creation,
            title: 'توليد فيديو',
            subtitle: 'واجهة جاهزة لربط محرك الفيديو',
            onTap: () => open(context, const CreateVideoScreen()),
          ),
          FeatureCard(
            icon: Icons.auto_fix_high,
            title: 'تعديل صورة',
            subtitle: 'ارفع صورة واكتب التعديل المطلوب',
            onTap: () => open(context, const EditImageScreen()),
          ),
          FeatureCard(
            icon: Icons.play_circle,
            title: 'صورة إلى فيديو',
            subtitle: 'حرّك صورتك باستخدام وصف للحركة',
            onTap: () => open(context, const ImageToVideoScreen()),
          ),
          FeatureCard(
            icon: Icons.photo_library,
            title: 'أعمالي',
            subtitle: 'مكان حفظ وعرض الأعمال لاحقاً',
            onTap: () => open(context, const WorksScreen()),
          ),
          FeatureCard(
            icon: Icons.settings,
            title: 'الإعدادات',
            subtitle: 'إعدادات التطبيق',
            onTap: () => open(context, const SettingsScreen()),
          ),
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

  void generate() {
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اكتب وصف للصورة الأول')));
      return;
    }
    setState(() => loading = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => loading = false);
      showDialog(context: context, builder: (_) => const AlertDialog(
        title: Text('نسخة البداية'),
        content: Text('الواجهة شغالة. خطوة الربط التالية هي توصيل محرك توليد صور مجاني/مفتوح المصدر بالـ API.'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) => ToolScaffold(
    title: 'توليد صورة',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: controller,
        maxLines: 6,
        decoration: const InputDecoration(
          labelText: 'وصف الصورة',
          hintText: 'مثال: شاب مصري واقف في شارع ليلاً بإضاءة سينمائية واقعية',
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<String>(
        value: ratio,
        decoration: const InputDecoration(labelText: 'نسبة الصورة', border: OutlineInputBorder()),
        items: ['1:1','4:5','16:9','9:16'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (v) => setState(() => ratio = v!),
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: loading ? null : generate,
        icon: loading ? const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.auto_awesome),
        label: Text(loading ? 'جاري التجهيز...' : 'توليد الصورة'),
      ),
    ]),
  );
}

class CreateVideoScreen extends StatelessWidget {
  const CreateVideoScreen({super.key});
  @override
  Widget build(BuildContext context) => ToolScaffold(
    title: 'توليد فيديو',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const TextField(maxLines: 6, decoration: InputDecoration(
        labelText: 'وصف الفيديو',
        hintText: 'مثال: سيارة رياضية تتحرك في مدينة مستقبلية ليلاً',
        border: OutlineInputBorder(),
      )),
      const SizedBox(height: 16),
      const Text('المدة'),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value:'5', label:Text('5 ثواني')),
          ButtonSegment(value:'10', label:Text('10 ثواني')),
        ],
        selected: const {'5'},
        onSelectionChanged: (_) {},
      ),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الواجهة جاهزة — سيتم ربط محرك الفيديو في المرحلة التالية.'))),
        icon: const Icon(Icons.movie_creation),
        label: const Text('إنشاء الفيديو'),
      ),
    ]),
  );
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
  Widget build(BuildContext context) => ToolScaffold(
    title: 'تعديل صورة',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (image != null)
        ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(image!.path), height: 260, fit: BoxFit.cover))
      else
        Container(height: 220, alignment: Alignment.center, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
          child: const Text('لم يتم اختيار صورة')),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: pick, icon: const Icon(Icons.upload), label: const Text('اختيار صورة من الهاتف')),
      const SizedBox(height: 14),
      TextField(controller: prompt, maxLines: 4, decoration: const InputDecoration(
        labelText: 'اكتب التعديل المطلوب',
        hintText: 'مثال: غيّر الخلفية لمكان فاخر وحافظ على ملامح الوجه',
        border: OutlineInputBorder())),
      const SizedBox(height: 14),
      FilledButton(onPressed: image == null ? null : () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم استلام الطلب — محرك التعديل سيُربط في المرحلة التالية.')));
      }, child: const Text('تنفيذ التعديل')),
    ]),
  );
}

class ImageToVideoScreen extends StatefulWidget {
  const ImageToVideoScreen({super.key});
  @override
  State<ImageToVideoScreen> createState() => _ImageToVideoScreenState();
}
class _ImageToVideoScreenState extends State<ImageToVideoScreen> {
  XFile? image;
  final motion = TextEditingController();

  Future<void> pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (p != null) setState(() => image = p);
  }

  @override
  Widget build(BuildContext context) => ToolScaffold(
    title: 'صورة إلى فيديو',
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (image != null)
        ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(File(image!.path), height: 260, fit: BoxFit.cover))
      else
        Container(height: 220, alignment: Alignment.center, decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white24)),
          child: const Text('اختار صورة')),
      const SizedBox(height: 14),
      OutlinedButton.icon(onPressed: pick, icon: const Icon(Icons.photo), label: const Text('اختيار صورة')),
      const SizedBox(height: 14),
      TextField(controller: motion, maxLines: 4, decoration: const InputDecoration(
        labelText: 'وصف الحركة',
        hintText: 'مثال: حركة كاميرا بطيئة مع نسيم يحرك الملابس',
        border: OutlineInputBorder())),
      const SizedBox(height: 14),
      FilledButton(onPressed: image == null ? null : () {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الواجهة جاهزة للربط بمحرك Image-to-Video.')));
      }, child: const Text('إنشاء الفيديو')),
    ]),
  );
}

class WorksScreen extends StatelessWidget {
  const WorksScreen({super.key});
  @override
  Widget build(BuildContext context) => ToolScaffold(
    title: 'أعمالي',
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: const [
      Icon(Icons.photo_library_outlined, size: 80),
      SizedBox(height: 14),
      Text('لسه مفيش أعمال محفوظة'),
      SizedBox(height: 8),
      Text('بعد ربط محرك الذكاء الاصطناعي هنضيف الحفظ والمشاركة هنا.'),
    ])),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => ToolScaffold(
    title: 'الإعدادات',
    child: ListView(children: const [
      ListTile(leading: Icon(Icons.language), title: Text('اللغة'), subtitle: Text('العربية')),
      ListTile(leading: Icon(Icons.info_outline), title: Text('عن التطبيق'), subtitle: Text('AI Creator — الإصدار 1.0.0')),
      ListTile(leading: Icon(Icons.cloud_off), title: Text('محرك الذكاء الاصطناعي'), subtitle: Text('غير متصل حالياً — سيتم ربطه في المرحلة التالية')),
    ]),
  );
}

class ToolScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const ToolScaffold({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  );
}
