class Planta {
  final String id;
  final String nome;
  final String nomeCientifico;
  final String emoji;
  final String descricao;
  final String luminosidade;
  final String rega;
  final String dificuldade;
  final String dica;

  const Planta({
    required this.id,
    required this.nome,
    required this.nomeCientifico,
    required this.emoji,
    required this.descricao,
    required this.luminosidade,
    required this.rega,
    required this.dificuldade,
    required this.dica,
  });

  factory Planta.fromJson(Map<String, dynamic> json) {
    return Planta(
      id: json['id'] as String,
      nome: json['nome'] as String,
      nomeCientifico: json['nomeCientifico'] as String,
      emoji: json['emoji'] as String,
      descricao: json['descricao'] as String,
      luminosidade: json['luminosidade'] as String,
      rega: json['rega'] as String,
      dificuldade: json['dificuldade'] as String,
      dica: json['dica'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'nomeCientifico': nomeCientifico,
      'emoji': emoji,
      'descricao': descricao,
      'luminosidade': luminosidade,
      'rega': rega,
      'dificuldade': dificuldade,
      'dica': dica,
    };
  }
}
