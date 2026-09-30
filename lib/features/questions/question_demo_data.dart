import 'domain/question.dart';

final demoQuestions = [
  Question(
    id: 'question-001',
    number: 1,
    statement: 'Qual é a função principal da camada de transporte?',
    alternatives: [
      'Entregar dados entre processos ponta a ponta.',
      'Definir o endereço MAC dos dispositivos.',
      'Controlar os sinais elétricos do cabo.',
      'Armazenar arquivos no servidor.',
      'Desenhar a topologia física da rede.',
    ],
    correctAlternativeIndex: 0,
    explanation: 'A camada de transporte oferece comunicação entre processos e pode fornecer controle de fluxo e confiabilidade.',
    contest: 'Demonstração',
    role: 'Análise de Sistemas',
    topic: 'Redes',
    exam: 'Prova demonstrativa 1',
    createdAt: DateTime(2026, 9, 30),
  ),
  Question(
    id: 'question-002',
    number: 2,
    statement: 'Qual topologia conecta os dispositivos a um ponto central?',
    alternatives: [
      'Anel',
      'Barramento',
      'Estrela',
      'Malha parcial',
      'Ponto a ponto',
    ],
    correctAlternativeIndex: 2,
    explanation: 'Na topologia em estrela, cada dispositivo possui uma conexão individual com um concentrador central.',
    contest: 'Demonstração',
    role: 'Infraestrutura',
    topic: 'Topologias',
    exam: 'Prova demonstrativa 1',
    createdAt: DateTime(2026, 9, 30),
  ),
];
