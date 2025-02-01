import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '"Khudi ko kar buland itna ke har taqdir se pehle,\nKhuda bande se khud pooche, bata teri raza kya hai?"',
                style: TextStyle(
                  fontFamily: 'JameelNooriNastaleeq',
                  fontSize: 20,
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 24),

            // About Iqbal Section
            Text(
              'About Allama Iqbal & This App',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'Allama Iqbal, the visionary poet-philosopher of the East, dedicated his life to reawakening the Muslim Ummah through spiritual revival and intellectual empowerment. His philosophy of Khudi (self-realization) ignited a transformative movement urging Muslims to embrace self-awareness, unity, and progress through knowledge and faith. His timeless verses not only inspired the creation of Pakistan but continue to guide millions in reclaiming their identity and purpose.\n\nThis app is a digital tribute to Iqbal\'s wisdom, designed to make his revolutionary teachings accessible to modern seekers. Here, you\'ll explore his poetry, reflect on his philosophical insights, and discover how to embody his ideals in today\'s world.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Developer Section
            Text(
              'About the Developer',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Hashim Hameem'),
                      subtitle: Text('Full-stack & Android developer from Kashmir'),
                    ),
                    const Divider(),
                    Text('Languages & Tools:', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Android', 'NextJS', 'JavaScript', 'Java', 'Python', 'PHP',
                        'HTML5', 'Node.js', 'Express', 'Flask', 'Bootstrap',
                        'MSSQL', 'MySQL', 'SQLite'
                      ].map((skill) => Chip(label: Text(skill))).toList(),
                    ),
                    const Divider(),
                    Text('Let\'s Connect:', style: theme.textTheme.titleMedium),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email'),
                      subtitle: const Text('hashimdar141@yahoo.com'),
                      onTap: () => _launchUrl('mailto:hashimdar141@yahoo.com'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: const Text('Twitter'),
                      subtitle: const Text('@HashimScnz'),
                      onTap: () => _launchUrl('https://twitter.com/HashimScnz'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.work),
                      title: const Text('LinkedIn'),
                      subtitle: const Text('Hashim Hameem'),
                      onTap: () => _launchUrl('https://linkedin.com/in/hashim-hameem'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Footer Quote
            Text(
              '"This app is my humble effort to honor Iqbal\'s legacy – may his words continue to light our path."',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
