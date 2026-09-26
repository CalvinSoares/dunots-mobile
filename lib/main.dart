import 'package:flutter/material.dart';

void main() {
  runApp(const DunotsMobileApp());
}

class DunotsMobileApp extends StatelessWidget {
  const DunotsMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF202321);
    const panel = Color(0xFF292D2A);
    const ink = Color(0xFFF2EEE4);
    const muted = Color(0xFFB6B7AD);
    const coral = Color(0xFFFF7168);
    const blue = Color(0xFF78B8FF);

    final scheme = ColorScheme.fromSeed(
      seedColor: coral,
      brightness: Brightness.dark,
      surface: panel,
    ).copyWith(surface: panel, onSurface: ink, primary: coral, secondary: blue);

    return MaterialApp(
      title: 'Dunots',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: background,
        cardTheme: const CardThemeData(
          color: panel,
          margin: EdgeInsets.zero,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: panel,
          indicatorColor: coral.withValues(alpha: 0.18),
          labelTextStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, color: muted),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: panel,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4A504B)),
          ),
        ),
      ),
      home: const DunotsHomeShell(),
    );
  }
}

class DunotsHomeShell extends StatefulWidget {
  const DunotsHomeShell({super.key});

  @override
  State<DunotsHomeShell> createState() => _DunotsHomeShellState();
}

class _DunotsHomeShellState extends State<DunotsHomeShell> {
  int selectedIndex = 0;

  static const pages = <Widget>[
    TodayPage(),
    FlashcardsPreviewPage(),
    RoadmapsPreviewPage(),
    MorePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Hoje',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style),
            label: 'Cards',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Trilhas',
          ),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'Mais'),
        ],
      ),
    );
  }
}

class TodayPage extends StatelessWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DunotsBrand(),
          const SizedBox(height: 28),
          Text(
            'seu caderno de estudos',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(color: const Color(0xFFB6B7AD)),
          ),
          const SizedBox(height: 4),
          Text(
            'Vamos avançar um pouco hoje?',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 22),
          const ReviewCard(),
          const SizedBox(height: 18),
          Row(
            children: const [
              Expanded(
                child: MetricCard(
                  label: 'flashcards',
                  value: '128',
                  icon: Icons.style_outlined,
                  color: Color(0xFF78B8FF),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'trilhas ativas',
                  value: '3',
                  icon: Icons.route_outlined,
                  color: Color(0xFFB79BFF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'acesso rápido',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const QuickAction(
            icon: Icons.play_arrow_rounded,
            title: 'Começar revisão',
            subtitle: '32 cartões aguardando',
            color: Color(0xFFFF7168),
          ),
          const SizedBox(height: 10),
          const QuickAction(
            icon: Icons.assignment_outlined,
            title: 'Continuar simulado',
            subtitle: 'Análise de Sistemas · 39/70',
            color: Color(0xFFFFC857),
          ),
        ],
      ),
    );
  }
}

class FlashcardsPreviewPage extends StatelessWidget {
  const FlashcardsPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewPage(
      icon: Icons.style_outlined,
      title: 'Flashcards',
      subtitle: 'A revisão espaçada vai morar aqui.',
      child: const Column(
        children: [
          ExampleListTile(
            title: 'O que é independência de dados?',
            detail: 'Banco de dados · 2 revisões',
          ),
          SizedBox(height: 10),
          ExampleListTile(
            title: 'Como funciona o protocolo TCP?',
            detail: 'Redes · revisão amanhã',
          ),
        ],
      ),
    );
  }
}

class RoadmapsPreviewPage extends StatelessWidget {
  const RoadmapsPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewPage(
      icon: Icons.route_outlined,
      title: 'Trilhas de estudo',
      subtitle: 'Organize tópicos, sub tópicos e materiais.',
      child: const Column(
        children: [
          ExampleListTile(
            title: 'Análise de Sistemas',
            detail: '12 de 38 itens concluídos',
          ),
          SizedBox(height: 10),
          ExampleListTile(
            title: 'Infraestrutura de Redes',
            detail: '5 de 24 itens concluídos',
          ),
        ],
      ),
    );
  }
}

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PreviewPage(
      icon: Icons.more_horiz,
      title: 'Mais',
      subtitle: 'Provas, desafios, sincronização e configurações.',
      child: const Column(
        children: [
          ExampleListTile(
            title: 'Provas e simulados',
            detail: 'Questões e resultados',
          ),
          SizedBox(height: 10),
          ExampleListTile(
            title: 'Sincronização',
            detail: 'Conectar ao seu Dunots desktop',
          ),
        ],
      ),
    );
  }
}

class DunotsBrand extends StatelessWidget {
  const DunotsBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFFF7168).withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.edit_note_rounded,
            color: Color(0xFFFF7168),
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'dunots',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        ),
      ],
    );
  }
}

class ReviewCard extends StatelessWidget {
  const ReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7168).withValues(alpha: 0.12),
        border: Border.all(
          color: const Color(0xFFFF7168).withValues(alpha: 0.55),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: Color(0xFFFF7168), size: 19),
              SizedBox(width: 8),
              Text(
                'revisões de hoje',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '32',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFF7168),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'cartões esperando por você',
            style: TextStyle(color: Color(0xFFB6B7AD)),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('começar revisão'),
          ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF292D2A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4A504B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 9),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFB6B7AD), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const QuickAction({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF292D2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4A504B)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFB6B7AD),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB6B7AD)),
        ],
      ),
    );
  }
}

class PreviewPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const PreviewPage({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFFF7168)),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(subtitle, style: const TextStyle(color: Color(0xFFB6B7AD))),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class ExampleListTile extends StatelessWidget {
  final String title;
  final String detail;

  const ExampleListTile({super.key, required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF292D2A),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF4A504B)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.radio_button_unchecked,
            color: Color(0xFF78B8FF),
            size: 21,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Color(0xFFB6B7AD),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFB6B7AD)),
        ],
      ),
    );
  }
}
