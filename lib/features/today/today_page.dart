import 'package:flutter/material.dart';

import '../../shared/widgets/study_widgets.dart';

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
          const Row(
            children: [
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
