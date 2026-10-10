# Jardim Fácil

Aplicativo Flutter com um catálogo de plantas comuns de casa e apartamento.
Cada planta tem uma tela de detalhes com luminosidade, frequência de rega,
nível de dificuldade e uma dica de cuidado. Projeto da disciplina de
Programação para Dispositivos Móveis (IFBA).

## Funcionalidades

**Usuário anônimo**
- Ver a lista de plantas, buscar pelo nome e filtrar por dificuldade.
- Abrir os detalhes de qualquer planta.

**Usuário logado (login simulado)**
- Tudo o que o anônimo faz.
- Favoritar e desfavoritar plantas (coração na lista ou botão nos detalhes).
- Acessar a tela "Meu jardim" com as plantas escolhidas.
- Sair da conta (logoff) com confirmação.

## Credenciais de teste

| Nome | E-mail | Senha |
|------|--------|-------|
| Maria Silva | maria@jardim.com | 123456 |
| João Souza | joao@jardim.com | 123456 |

O login é apenas simulado (mock), não há servidor.

## Estrutura de pastas

```
lib/
  main.dart                 # ponto de entrada e tema
  models/                   # Planta e Usuario
  services/                 # repositório de plantas, autenticação e favoritos
  screens/                  # lista, detalhes, login e Meu jardim
  widgets/                  # PlantaCard, DificuldadeChip, InfoCard
assets/data/
  plantas.json              # dados das plantas
  favoritos.json            # favoritos iniciais por usuário
test/                       # testes de dados e de interface
```

## Como executar

```bash
flutter pub get
flutter run            # com um emulador Android aberto ou dispositivo conectado
```

Alternativas:

```bash
flutter run -d chrome  # executa no navegador
flutter build web      # gera a versão web em build/web
```

Testes e análise estática:

```bash
flutter analyze
flutter test
```

## Dados

Os dados ficam em `assets/data/*.json` e são carregados com `rootBundle`.
