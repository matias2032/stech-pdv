// lib/models/produto_imagem_model.dart

class ProdutoImagem {
  final int? idImagem;
  final int idProduto;
  final String caminhoImagem;
  final String? legenda;
  final int imagemPrincipal;

  ProdutoImagem({
    this.idImagem,
    required this.idProduto,
    required this.caminhoImagem,
    this.legenda,
    this.imagemPrincipal = 0,
  });

  factory ProdutoImagem.fromJson(Map<String, dynamic> json) {
    return ProdutoImagem(
      idImagem: json['idImagem'],
      idProduto: json['idProduto'],
      caminhoImagem: json['caminhoImagem'],
      legenda: json['legenda'],
      imagemPrincipal: json['imagemPrincipal'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (idImagem != null) 'idImagem': idImagem,
      'idProduto': idProduto,
      'caminhoImagem': caminhoImagem,
      'legenda': legenda,
      'imagemPrincipal': imagemPrincipal,
    };
  }
}