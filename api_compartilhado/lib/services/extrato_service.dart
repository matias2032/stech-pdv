import 'package:api_compartilhado/api_compartilhado.dart';
import '../models/extrato_model.dart';
import 'package:http/http.dart' as http;


class ExtratoService {
  static final ExtratoService instance = ExtratoService._();
  ExtratoService._();

  /// Tipos de documento incluídos nos extractos.
  static const _tiposPermitidos = {'FAT', 'VD'};

  /// Gera um [ExtratoModel] consultando os serviços existentes.
  ///
  /// Fluxo:
  ///   1. Lista todos os documentos fiscais.
  ///   2. Filtra por tipo (FAT / VD) e pelo período.
  ///   3. Para cada documento, busca o pedido (total) e o cliente (nome/NUIT).
  Future<ExtratoModel> gerar({
    required DateTime dataInicio,
    required DateTime dataFim,
    required String labelPeriodo,
  }) async {
    final docService     = DocumentoFiscalService();
    final pedidoService  = PedidoService();
    final clienteService = ClienteService(
  baseUrl: ApiConfig.baseUrl,
  httpClient: http.Client(),
);
    // 1. Todos os documentos
    final todos = await docService.listarTodos();

    // 2. Filtrar por tipo e período (não anulados)
    final filtrados = todos.where((d) {
      if (d.anulado) return false;
      if (!_tiposPermitidos.contains(d.tipoDocumento.codigo)) return false;
      final dt = d.emitidoEm;
      return !dt.isBefore(dataInicio) && !dt.isAfter(dataFim);
    }).toList();

    // 3. Montar linhas com dados de pedido + cliente
    final linhas = <LinhaExtrato>[];

    for (final doc in filtrados) {
      try {
        final pedido = await pedidoService.buscarPorId(doc.idPedido);

        String nomeEmpresa = 'Cliente Avulso';
        String? nuit;

        if (pedido.idCliente != null) {
          try {
            final cliente = await clienteService.buscarPorId(pedido.idCliente!);
            final nome    = '${cliente.nome ?? ''} ${cliente.apelido ?? ''}'.trim();
            nomeEmpresa   = nome.isEmpty ? 'Cliente #${cliente.id}' : nome;
            nuit          = cliente.nuit;
          } catch (_) {
            nomeEmpresa = 'Cliente #${pedido.idCliente}';
          }
        }

        linhas.add(LinhaExtrato(
          dataEmissao:     doc.emitidoEm,
          numeroDocumento: doc.referencia,
          nomeEmpresa:     nomeEmpresa,
          nuit:            nuit,
          valorTotal:      pedido.total,
        ));
      } catch (_) {
        // documento sem pedido acessível — ignorar
      }
    }

    // Ordenar por data crescente
    linhas.sort((a, b) => a.dataEmissao.compareTo(b.dataEmissao));

    return ExtratoModel(
      linhas:       linhas,
      dataInicio:   dataInicio,
      dataFim:      dataFim,
      labelPeriodo: labelPeriodo,
    );
  }
}