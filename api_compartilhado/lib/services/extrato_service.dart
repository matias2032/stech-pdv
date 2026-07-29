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
    final despesaService = DespesaService();
    final clienteService = ClienteService(
  baseUrl: ApiConfig.baseUrl,
  httpClient: http.Client(),
);
// 1. Todos os documentos (necessário ver TODOS, não só FAT/VD, para
    //    conseguir localizar as NCR/NDB associadas a cada factura pelo
    //    mesmo idPedido — a API não expõe directamente a relação
    //    documento_fiscal_relacao).
    final todos = await docService.listarTodos();

    // 1.1 Agrupar NCR/NDB não anuladas por idPedido, para consulta O(1)
    //     ao montar cada linha de factura.
    final Map<int, List<DocumentoFiscalModel>> notasPorPedido = {};
    for (final d in todos) {
      final codigo = d.tipoDocumento.codigo;
      if ((codigo == 'NCR' || codigo == 'NDB') && !d.anulado) {
        notasPorPedido.putIfAbsent(d.idPedido, () => []).add(d);
      }
    }

    // 2. Filtrar por tipo e período (não anulados)
final filtrados = todos.where((d) {
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

final nomeSingular = [
  pedido.nomeClienteSingular,
  pedido.apelidoClienteSingular,
]
    .where((v) => v != null && v.trim().isNotEmpty)
    .map((v) => v!.trim())
    .join(' ');

if (nomeSingular.isNotEmpty) {
  nomeEmpresa = nomeSingular;
  nuit = null;
} else if (pedido.idCliente != null) {
  try {
    final cliente = await clienteService.buscarPorId(pedido.idCliente!);
    nomeEmpresa = cliente.nomeCompleto;
    nuit = cliente.nuit;
    print('>>> NUIT do cliente: "${nuit}" | bytes: ${nuit?.codeUnits}');
  } catch (_) {
    nomeEmpresa = 'Cliente #${pedido.idCliente}';
  }
}

// Valor congelado no momento da emissão (snapshot). Só recai sobre o
// total ao vivo do pedido para documentos antigos, emitidos antes de
// existir esta coluna — nunca para documentos novos.
final valorFactura = doc.valorTotalEmissao ?? pedido.total;

linhas.add(LinhaExtrato(
  dataEmissao:     doc.emitidoEm,
  numeroDocumento: doc.referencia,
  nomeEmpresa:     nomeEmpresa,
  nuit:            nuit,
  valorTotal:      valorFactura,
  estado:          doc.anulado ? 'ANULADO' : '-',
));

// Linha(s) de ajuste — Nota(s) de Crédito/Débito associadas a esta
// factura pelo mesmo pedido. NCR entra a subtrair, NDB a somar.
final notas = notasPorPedido[doc.idPedido];
if (notas != null) {
  for (final nota in notas) {
    final ehCredito = nota.tipoDocumento.codigo == 'NCR';
    final valorAjuste = (nota.valorTotalEmissao ?? 0) * (ehCredito ? -1 : 1);
    if (valorAjuste == 0) continue;

linhas.add(LinhaExtrato(
      dataEmissao:     nota.emitidoEm,
      numeroDocumento: nota.referencia,
      nomeEmpresa:     'Ref. ${doc.referencia}',
      nuit:            null,
      valorTotal:      valorAjuste,
      estado:          '-',
      isAjusteNotaRetificativa: true,
    ));
  }
}
      } catch (_) {
        // documento sem pedido acessível — ignorar
      }
    }

final todasDespesas = await despesaService.listar();
print('>>> total despesas na BD: ${todasDespesas.length}');

final despesasRaw = todasDespesas.where((d) {
  if (d.dataDespesa == null) {
    print('   [IGNORADA] sem data: ${d.descricao}');
    return false;
  }
  final dentroDoIntervalo = !d.dataDespesa!.isBefore(dataInicio) &&
                            !d.dataDespesa!.isAfter(dataFim);
  print('   [${dentroDoIntervalo ? "OK" : "FORA"}] ${d.descricao} | data: ${d.dataDespesa} | inicio: $dataInicio | fim: $dataFim');
  return dentroDoIntervalo;
}).toList();

print('>>> despesas no período: ${despesasRaw.length}');

final despesas = despesasRaw.map((d) {
  return LinhaDespesaExtrato(
    dataDespesa: d.dataDespesa ?? DateTime.now(),
    descricao: d.descricao,
    nomeFornecedor: d.nomeFornecedor?.trim().isNotEmpty == true
        ? d.nomeFornecedor!.trim()
        : 'Sem fornecedor',
    nuitFornecedor: d.nuitFornecedor,
    valorGasto: d.valorGasto,
    idTipoDespesa: d.idTipoDespesa,
    nomeTipoDespesa: d.nomeTipoDespesa,
  );
}).toList();



    // Ordenar por data crescente
    linhas.sort((a, b) => a.dataEmissao.compareTo(b.dataEmissao));

return ExtratoModel(
  linhas: linhas,
  despesas: despesas,
  dataInicio: dataInicio,
  dataFim: dataFim,
  labelPeriodo: labelPeriodo,
);
  }
}