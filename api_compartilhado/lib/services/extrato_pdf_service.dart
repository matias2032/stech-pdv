import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:api_compartilhado/api_compartilhado.dart';

import '../models/extrato_model.dart';

const _kAzul     = PdfColor.fromInt(0xFF1B2A6B);
const _kVermelho = PdfColor.fromInt(0xFFC8102E);

class ExtratoPdfService {
  static final ExtratoPdfService instance = ExtratoPdfService._();
  ExtratoPdfService._();

  final _fmtData     = DateFormat('dd/MM/yyyy');
  final _fmtMoeda    = NumberFormat.currency(locale: 'pt_PT', symbol: 'MZN');
  final _fmtNomeArq  = DateFormat('yyyyMMdd_HHmm');

  Future<File> gerar(ExtratoModel extrato) async {
    final pdf = await _build(extrato);
    return _salvar(pdf, extrato);
  }

  Future<void> abrirPdf(File file) async {
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception('Erro ao abrir PDF: ${result.message}');
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  Future<pw.Document> _build(ExtratoModel extrato) async {
    final iconBytes = await rootBundle.load('assets/icon/app_icon.png');
    final iconImage = pw.MemoryImage(iconBytes.buffer.asUint8List());

    final doc = pw.Document(
      title:  'Extracto ${extrato.labelPeriodo}',
      author: 'Stech Engenharia',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin:     const pw.EdgeInsets.fromLTRB(30, 28, 30, 20),
        footer:     (ctx) => _rodapePagina(ctx),
        build:      (ctx) => [
          _cabecalho(extrato, iconImage),
          pw.SizedBox(height: 10),
          _tabela(extrato),
          pw.SizedBox(height: 12),
          _rodapeTotais(extrato),
          pw.SizedBox(height: 8),
          _notaFiscal(),
        ],
      ),
    );

    return doc;
  }

  
Future<File> gerarHistoricoCliente({
  required ClienteModel cliente,
  required Map<String, dynamic> extracto,
}) async {
  final pdf = await _buildHistoricoCliente(cliente, extracto);
  return _salvarHistoricoCliente(pdf, cliente);
}

// ── NOVO: PDF com extracto documental do cliente ─────────────────────────

Future<File> gerarExtractoDocumentalCliente({
  required ClienteModel cliente,
  required Map<String, dynamic> extractoDocumental,
}) async {
  final linhasRaw = (extractoDocumental['linhas'] as List?) ?? const [];
  final linhas = linhasRaw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  final totalDocumentos =
      (extractoDocumental['totalDocumentos'] as num?)?.toInt() ??
      linhas.length;
  final somaTotal =
      (extractoDocumental['somaTotal'] as num?)?.toDouble() ?? 0.0;

  // Reutiliza ExtratoModel para aproveitar _build() e _tabela() existentes
  final linhasExtrato = linhas.map((l) {
    final emitidoEmStr = l['emitidoEm']?.toString();
    final emitidoEm =
        emitidoEmStr != null ? DateTime.tryParse(emitidoEmStr) : DateTime.now();
    return LinhaExtrato(
      dataEmissao: emitidoEm ?? DateTime.now(),
      numeroDocumento: (l['referencia'] ?? '—').toString(),
      nomeEmpresa: cliente.nomeCompleto,
      nuit: cliente.nuit,
      valorTotal: (l['valorTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }).toList();

  final dataInicio = linhasExtrato.isNotEmpty
      ? linhasExtrato
          .map((l) => l.dataEmissao)
          .reduce((a, b) => a.isBefore(b) ? a : b)
      : DateTime.now();
  final dataFim = linhasExtrato.isNotEmpty
      ? linhasExtrato
          .map((l) => l.dataEmissao)
          .reduce((a, b) => a.isAfter(b) ? a : b)
      : DateTime.now();

  final extrato = ExtratoModel(
    linhas: linhasExtrato,
    dataInicio: dataInicio,
    dataFim: dataFim,
    labelPeriodo:
        '${_fmtData.format(dataInicio)} a ${_fmtData.format(dataFim)}',
  );

  final pdf = await _buildExtractoDocumentalCliente(extrato, cliente);

  final nomeCliente = cliente.nomeCompleto
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(' ', '_');
  final nome =
      'EXTRATO_DOCUMENTAL-$nomeCliente-${_fmtNomeArq.format(DateTime.now())}.pdf';
  final dir = await _resolveDirectory();
  final file = File('${dir.path}/$nome');
  await file.writeAsBytes(await pdf.save());
  return file;
}

Future<pw.Document> _buildExtractoDocumentalCliente(
  ExtratoModel extrato,
  ClienteModel cliente,
) async {
  final iconBytes = await rootBundle.load('assets/icon/app_icon.png');
  final iconImage = pw.MemoryImage(iconBytes.buffer.asUint8List());

  final doc = pw.Document(
    title: 'Extracto Documental — ${cliente.nomeCompleto}',
    author: 'Stech Engenharia',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 20),
      footer: (ctx) => _rodapePagina(ctx),
build: (ctx) => [
  _cabecalho(extrato, iconImage),

  pw.SizedBox(height: 10),
  _tituloTabela('DOCUMENTOS FISCAIS EMITIDOS'),
  pw.SizedBox(height: 4),
  _tabela(extrato),

  pw.SizedBox(height: 14),
  _tituloTabela('DESPESAS REGISTADAS'),
  pw.SizedBox(height: 4),
  _tabelaDespesas(extrato),

  pw.SizedBox(height: 12),
  _rodapeTotais(extrato),

  pw.SizedBox(height: 8),
  _notaFiscal(),
],
    ),
  );

  return doc;
}

pw.Widget _cabecalhoClienteDocumental(
  ExtratoModel extrato,
  ClienteModel cliente,
  pw.MemoryImage icon,
) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(icon, width: 135, height: 80, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 6),
              _t('Segurança Tecnologica SU, LDA (Stech Engenharia)',
                  bold: true, size: 8.5),
              pw.SizedBox(height: 2),
              _t('Bairro: Chingodzi, Tete', size: 8),
              _t('Número: +258 84 239 0756 ou 87 939 0756', size: 8),
              _t('Email: info@stech.co.mz', size: 8),
              _t('Website: www.stecheng.co.mz', size: 8),
              _t('NUIT: 401 684 530', size: 8),
            ],
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _t(
                  'EXTRACTO DOCUMENTAL DO CLIENTE',
                  size: 15,
                  bold: true,
                  color: _kAzul,
                ),
                pw.SizedBox(height: 4),
                _t(
                  cliente.nomeCompleto,
                  size: 11,
                  bold: true,
                  color: _kVermelho,
                ),
                if (cliente.nuit?.isNotEmpty == true)
                  _t('NUIT: ${cliente.nuit}', size: 8,
                      color: PdfColors.grey700),
                pw.SizedBox(height: 4),
                _t(
                  'Período: ${_fmtData.format(extrato.dataInicio)}'
                  ' a ${_fmtData.format(extrato.dataFim)}',
                  size: 9,
                  color: PdfColors.grey700,
                ),
                pw.SizedBox(height: 2),
                _t(
                  'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                  size: 8,
                  color: PdfColors.grey600,
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Divider(color: _kAzul, thickness: 2.5),
    ],
  );
}

Future<pw.Document> _buildHistoricoCliente(
  ClienteModel cliente,
  Map<String, dynamic> extracto,
) async {
  final iconBytes = await rootBundle.load('assets/icon/app_icon.png');
  final iconImage = pw.MemoryImage(iconBytes.buffer.asUint8List());

  final doc = pw.Document(
    title: 'Histórico Comercial - ${cliente.nomeCompleto}',
    author: 'Stech Engenharia',
  );

  final linhasRaw = (extracto['linhas'] as List?) ?? const [];
  final linhas = linhasRaw
      .whereType<Map>()
      .map((e) => Map<String, dynamic>.from(e))
      .toList();

  final totalDivida = (extracto['totalDivida'] as num?)?.toDouble() ?? 0.0;
  final totalPago = (extracto['totalPago'] as num?)?.toDouble() ?? 0.0;
  final saldo = (extracto['saldo'] as num?)?.toDouble() ?? 0.0;
  final quantidadeRegistos = linhas.length;
final totalDocumentos =
    linhas.where((l) => l['idDocumentoFacturaCredito'] != null).length;

final pedidosPagos = linhas.where((l) {
  final status = (l['statusPagamento'] ?? '').toString().toUpperCase();
  return status == 'PAGO';
}).length;

final pedidosPendentes = linhas.where((l) {
  final status = (l['statusPagamento'] ?? '').toString().toUpperCase();
  return status == 'PENDENTE' || status == 'PARCIAL';
}).length;

final mensagemSituacao = saldo > 0
    ? 'Cliente devedor: possui saldo pendente e requer acompanhamento comercial.'
    : 'Cliente regular: não possui saldo pendente neste momento.';

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 20),
      footer: (ctx) => _rodapePagina(ctx),
      build: (ctx) => [
        _cabecalhoHistoricoCliente(cliente, iconImage),
        pw.SizedBox(height: 10),
     _resumoHistoricoCliente(
  cliente: cliente,
  totalDivida: totalDivida,
  totalPago: totalPago,
  saldo: saldo,
  quantidadeRegistos: quantidadeRegistos,
  pedidosPagos: pedidosPagos,
  pedidosPendentes: pedidosPendentes,
  totalDocumentos: totalDocumentos,
  mensagemSituacao: mensagemSituacao,
),
        pw.SizedBox(height: 12),
        _tabelaHistoricoCliente(linhas),
        pw.SizedBox(height: 12),
      _rodapeHistoricoCliente(
  totalDivida: totalDivida,
  totalPago: totalPago,
  saldo: saldo,
  totalDocumentos: totalDocumentos,
  quantidadeRegistos: quantidadeRegistos,
  pedidosPagos: pedidosPagos,
  pedidosPendentes: pedidosPendentes,
),
        pw.SizedBox(height: 8),
        _notaFiscal(),
      ],
    ),
  );

  return doc;
}

pw.Widget _cabecalhoHistoricoCliente(
  ClienteModel cliente,
  pw.MemoryImage icon,
) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(icon, width: 135, height: 80, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 6),
              _t('Segurança Tecnologica SU, LDA (Stech Engenharia)',
                  bold: true, size: 8.5),
              pw.SizedBox(height: 2),
              _t('Bairro: Chingodzi, Tete', size: 8),
              _t('Número: +258 84 239 0756 ou 87 939 0756', size: 8),
              _t('Email: info@stech.co.mz', size: 8),
              _t('Website: www.stecheng.co.mz', size: 8),
              _t('NUIT: 401 684 530', size: 8),
            ],
          ),
          pw.SizedBox(width: 20),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _t(
                  'HISTÓRICO COMERCIAL DO CLIENTE',
                  size: 16,
                  bold: true,
                  color: _kAzul,
                ),
                pw.SizedBox(height: 6),
                _t(
                  cliente.nomeCompleto,
                  size: 11,
                  bold: true,
                  color: _kVermelho,
                ),
                pw.SizedBox(height: 2),
                _t(
                  'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                  size: 8,
                  color: PdfColors.grey600,
                ),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Divider(color: _kAzul, thickness: 2.5),
    ],
  );
}

pw.Widget _resumoHistoricoCliente({
  required ClienteModel cliente,
  required double totalDivida,
  required double totalPago,
  required double saldo,
  required int quantidadeRegistos,
  required int pedidosPagos,
  required int pedidosPendentes,
  required int totalDocumentos,
  required String mensagemSituacao,
}) {
  final situacao = saldo > 0 ? 'EM DÍVIDA' : 'REGULAR';
final situacaoCor = saldo > 0 ? _kVermelho : PdfColors.green700;

return pw.Container(
  padding: const pw.EdgeInsets.all(12),
  decoration: pw.BoxDecoration(
    color: PdfColors.grey100,
    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _t('Dados do Cliente', size: 10, bold: true, color: _kAzul),
      pw.SizedBox(height: 8),
      pw.Wrap(
        spacing: 20,
        runSpacing: 6,
        children: [
          _t('Empresa: ${cliente.nomeCompleto}', size: 8),
          _t('NUIT: ${cliente.nuit?.isNotEmpty == true ? cliente.nuit! : '—'}', size: 8),
          _t('Contacto: ${cliente.contacto?.isNotEmpty == true ? cliente.contacto! : '—'}', size: 8),
          _t('Email: ${cliente.email?.isNotEmpty == true ? cliente.email! : '—'}', size: 8),
          _t('Morada: ${cliente.morada?.isNotEmpty == true ? cliente.morada! : '—'}', size: 8),
        ],
      ),
      pw.SizedBox(height: 10),

      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _t(
            'Situação: $situacao',
            size: 10,
            bold: true,
            color: situacaoCor,
          ),
          _t(
            'Registos: $quantidadeRegistos',
            size: 9,
            bold: true,
            color: _kAzul,
          ),
          _t(
            'Documentos: $totalDocumentos',
            size: 9,
            bold: true,
            color: _kAzul,
          ),
        ],
      ),

      pw.SizedBox(height: 8),

      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _t(
            'Total em crédito: ${_fmtMoeda.format(totalDivida)}',
            size: 9,
            bold: true,
            color: _kAzul,
          ),
          _t(
            'Total pago: ${_fmtMoeda.format(totalPago)}',
            size: 9,
            bold: true,
            color: PdfColors.green700,
          ),
          _t(
            'Saldo actual: ${_fmtMoeda.format(saldo)}',
            size: 9,
            bold: true,
            color: _kVermelho,
          ),
        ],
      ),

      pw.SizedBox(height: 8),

      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _t(
            'Pedidos pagos: $pedidosPagos',
            size: 9,
            bold: true,
            color: PdfColors.green700,
          ),
          _t(
            'Pendentes / parciais: $pedidosPendentes',
            size: 9,
            bold: true,
            color: PdfColors.orange700,
          ),
        ],
      ),

      pw.SizedBox(height: 10),

      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: situacaoCor == _kVermelho
              ? PdfColors.red50
              : PdfColors.green50,
          border: pw.Border.all(
            color: situacaoCor,
            width: 0.7,
          ),
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: _t(
          mensagemSituacao,
          size: 8.5,
          bold: true,
          color: situacaoCor,
        ),
      ),
    ],
  ),
);
}

pw.Widget _tabelaHistoricoCliente(List<Map<String, dynamic>> linhas) {
  const estiloHeader = pw.TextStyle(
    fontSize: 8,
    color: PdfColors.white,
  );
  const estiloCell = pw.TextStyle(fontSize: 8);
  final estiloCellBold = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
  );

  if (linhas.isEmpty) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Center(
        child: _t(
          'Nenhum histórico comercial encontrado para este cliente.',
          size: 9,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const {
  0: pw.FixedColumnWidth(100), // Pedido / Ref
  1: pw.FixedColumnWidth(72),  // Documento
  2: pw.FixedColumnWidth(68),  // Total
  3: pw.FixedColumnWidth(68),  // Pago
  4: pw.FixedColumnWidth(68),  // Saldo
  5: pw.FixedColumnWidth(72),  // Estado
},
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _kAzul),
        children: [
          _thCell('Pedido', estiloHeader),
          _thCell('Documento', estiloHeader),
          _thCell('Total', estiloHeader, align: pw.TextAlign.right),
          _thCell('Pago', estiloHeader, align: pw.TextAlign.right),
          _thCell('Saldo', estiloHeader, align: pw.TextAlign.right),
          _thCell('Estado', estiloHeader),
        ],
      ),
      for (int i = 0; i < linhas.length; i++)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isOdd ? PdfColors.grey100 : PdfColors.white,
          ),
          children: [
            _tdCell(
  '${(linhas[i]['referencia'] ?? '—').toString()}\nPedido #${(linhas[i]['idPedido'] ?? '—').toString()}',
  estiloCellBold,
),
            _tdCell(
  linhas[i]['idDocumentoFacturaCredito'] != null
      ? 'Doc. #${linhas[i]['idDocumentoFacturaCredito']}'
      : 'Pendente',
  estiloCell,
),
            _tdCell(
              _fmtMoeda.format(((linhas[i]['total'] as num?) ?? 0).toDouble()),
              estiloCell,
              align: pw.TextAlign.right,
            ),
            _tdCell(
              _fmtMoeda.format(((linhas[i]['valorPago'] as num?) ?? 0).toDouble()),
              estiloCell,
              align: pw.TextAlign.right,
            ),
            _tdCell(
              _fmtMoeda.format(((linhas[i]['saldo'] as num?) ?? 0).toDouble()),
              estiloCell,
              align: pw.TextAlign.right,
            ),
            _tdCell(
              _statusLabelPdf((linhas[i]['statusPagamento'] ?? '—').toString()),
              estiloCell,
            ),
          ],
        ),
    ],
  );
}

pw.Widget _rodapeHistoricoCliente({
  required double totalDivida,
  required double totalPago,
  required double saldo,
  required int totalDocumentos,
  required int quantidadeRegistos,
  required int pedidosPagos,
  required int pedidosPendentes,
}) {
  return pw.Container(
  padding: const pw.EdgeInsets.all(12),
  decoration: pw.BoxDecoration(
    color: PdfColors.grey100,
    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
    borderRadius: pw.BorderRadius.circular(4),
  ),
  child: pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t('Total de registos:', size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 2),
              _t('$quantidadeRegistos', size: 12, bold: true, color: _kAzul),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t('Total de documentos:', size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 2),
              _t('$totalDocumentos', size: 12, bold: true, color: _kAzul),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t('Pedidos pagos:', size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 2),
              _t('$pedidosPagos', size: 12, bold: true, color: PdfColors.green700),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t('Pend./Parciais:', size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 2),
              _t('$pedidosPendentes', size: 12, bold: true, color: PdfColors.orange700),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 12),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _t('Total em crédito:', size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 2),
              _t(
                _fmtMoeda.format(totalDivida),
                size: 12,
                bold: true,
                color: _kAzul,
              ),
            ],
          ),
          pw.SizedBox(width: 24),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _t('Total pago:', size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 2),
              _t(
                _fmtMoeda.format(totalPago),
                size: 12,
                bold: true,
                color: PdfColors.green700,
              ),
            ],
          ),
          pw.SizedBox(width: 24),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _t('Saldo actual:', size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 2),
              _t(
                _fmtMoeda.format(saldo),
                size: 12,
                bold: true,
                color: _kVermelho,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
);
}

Future<File> _salvarHistoricoCliente(
  pw.Document pdf,
  ClienteModel cliente,
) async {
  final nomeCliente = cliente.nomeCompleto
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(' ', '_');

  final nome =
      'HISTORICO_CLIENTE-${nomeCliente}-${_fmtNomeArq.format(DateTime.now())}.pdf';

  final dir = await _resolveDirectory();
  final file = File('${dir.path}/$nome');
  await file.writeAsBytes(await pdf.save());
  return file;
}



  // ── Cabeçalho ────────────────────────────────────────────────────────────

  pw.Widget _cabecalho(ExtratoModel extrato, pw.MemoryImage icon) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Lado esquerdo: logo + dados da empresa ──────────────────
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Image(icon, width: 135, height: 80, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 6),
              _t('Segurança Tecnologica SU, LDA (Stech Engenharia)',
                  bold: true, size: 8.5),
              pw.SizedBox(height: 2),
              _t('Bairro: Chingodzi, Tete', size: 8),
              _t('Número: +258 84 239 0756 ou 87 939 0756', size: 8),
              _t('Email: info@stech.co.mz', size: 8),
              _t('Website: www.stecheng.co.mz', size: 8),
              _t('NUIT: 401 684 530', size: 8),
            ],
          ),
          pw.SizedBox(width: 20),

          // ── Lado direito: título + período ──────────────────────────
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              _t(
                'EXTRACTO DE DOCUMENTOS FISCAIS',
                size: 16,
                bold: true,
                color: _kAzul,
              ),
              pw.SizedBox(height: 6),
              _t(
                'Período: ${_fmtData.format(extrato.dataInicio)}'
                ' a ${_fmtData.format(extrato.dataFim)}',
                size: 9,
                color: PdfColors.grey700,
              ),
              pw.SizedBox(height: 2),
          _t(
  'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
  size: 8,
  color: PdfColors.grey600,
),
            ],
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Divider(color: _kAzul, thickness: 2.5),
    ],
  );
}



  // ── Tabela ───────────────────────────────────────────────────────────────
pw.Widget _tituloTabela(String titulo) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: pw.BoxDecoration(
      color: _kAzul,
      borderRadius: pw.BorderRadius.circular(3),
    ),
    child: _t(
      titulo,
      size: 8.5,
      bold: true,
      color: PdfColors.white,
    ),
  );
}


  pw.Widget _tabela(ExtratoModel extrato) {
    const estiloHeader = pw.TextStyle(
      fontSize: 8,
      color: PdfColors.white,
    );
    const estiloCell = pw.TextStyle(fontSize: 8);
    final estiloCellBold = pw.TextStyle(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(60),  // Data
        1: pw.FixedColumnWidth(80),  // Nº Documento
        2: pw.FlexColumnWidth(),     // Empresa
        3: pw.FixedColumnWidth(72),  // NUIT
        4: pw.FixedColumnWidth(88),  // Valor
      },
      children: [
        // Cabeçalho
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kAzul),
          children: [
            _thCell('Data',        estiloHeader),
            _thCell('Documento',   estiloHeader),
            _thCell('Empresa',     estiloHeader),
            _thCell('NUIT',        estiloHeader),
            _thCell('Valor Total', estiloHeader,
                align: pw.TextAlign.right),
          ],
        ),
        // Linhas de dados
        for (int i = 0; i < extrato.linhas.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i.isOdd ? PdfColors.grey100 : PdfColors.white,
            ),
            children: [
              _tdCell(
                _fmtData.format(extrato.linhas[i].dataEmissao),
                estiloCell,
              ),
              _tdCell(extrato.linhas[i].numeroDocumento, estiloCellBold),
              _tdCell(extrato.linhas[i].nomeEmpresa, estiloCell),
              _tdCell(extrato.linhas[i].nuit ?? '—', estiloCell),
              _tdCell(
                _fmtMoeda.format(extrato.linhas[i].valorTotal),
                estiloCell,
                align: pw.TextAlign.right,
              ),
            ],
          ),
      ],
    );
  }

  pw.Widget _tabelaDespesas(ExtratoModel extrato) {
  const estiloHeader = pw.TextStyle(
    fontSize: 8,
    color: PdfColors.white,
  );

  const estiloCell = pw.TextStyle(fontSize: 8);

  final estiloCellBold = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
  );

  if (extrato.despesas.isEmpty) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Center(
        child: _t(
          'Nenhuma despesa registada neste período.',
          size: 8.5,
          color: PdfColors.grey700,
        ),
      ),
    );
  }

  return pw.Table(
    border: pw.TableBorder.all(
      color: PdfColors.grey400,
      width: 0.5,
    ),
    columnWidths: const {
      0: pw.FixedColumnWidth(60),  // Data
      1: pw.FlexColumnWidth(2.5),  // Descrição
      2: pw.FlexColumnWidth(2),    // Fornecedor
      3: pw.FixedColumnWidth(70),  // NUIT
      4: pw.FixedColumnWidth(80),  // Valor
    },
    children: [
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: _kVermelho),
        children: [
          _thCell('Data', estiloHeader),
          _thCell('Descrição', estiloHeader),
          _thCell('Fornecedor', estiloHeader),
          _thCell('NUIT', estiloHeader),
          _thCell('Valor gasto', estiloHeader, align: pw.TextAlign.right),
        ],
      ),

      for (int i = 0; i < extrato.despesas.length; i++)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: i.isOdd ? PdfColors.grey100 : PdfColors.white,
          ),
          children: [
            _tdCell(
              _fmtData.format(extrato.despesas[i].dataDespesa),
              estiloCell,
            ),
            _tdCell(
              extrato.despesas[i].descricao,
              estiloCellBold,
            ),
            _tdCell(
              extrato.despesas[i].nomeFornecedor,
              estiloCell,
            ),
            _tdCell(
              extrato.despesas[i].nuitFornecedor?.isNotEmpty == true
                  ? extrato.despesas[i].nuitFornecedor!
                  : '—',
              estiloCell,
            ),
            _tdCell(
              _fmtMoeda.format(extrato.despesas[i].valorGasto),
              estiloCellBold,
              align: pw.TextAlign.right,
            ),
          ],
        ),
    ],
  );
}



  // ── Rodapé de totais ─────────────────────────────────────────────────────

  pw.Widget _rodapeTotais(ExtratoModel extrato) {
  final resultadoCor =
      extrato.resultadoLiquido >= 0 ? PdfColors.green700 : _kVermelho;

  return pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _blocoResumo(
              titulo: 'Documentos emitidos',
              valor: '${extrato.totalDocumentos}',
              cor: _kAzul,
            ),
            _blocoResumo(
              titulo: 'Despesas registadas',
              valor: '${extrato.totalDespesasRegistadas}',
              cor: _kVermelho,
            ),
          ],
        ),

        pw.SizedBox(height: 12),

        pw.Divider(color: PdfColors.grey400, thickness: 0.5),

        pw.SizedBox(height: 8),

        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            _blocoFinanceiro(
              titulo: 'Total facturado / emitido',
              valor: _fmtMoeda.format(extrato.somaTotal),
              cor: _kAzul,
            ),
            pw.SizedBox(width: 24),
            _blocoFinanceiro(
              titulo: 'Total gasto',
              valor: _fmtMoeda.format(extrato.somaDespesas),
              cor: _kVermelho,
            ),
            pw.SizedBox(width: 24),
            _blocoFinanceiro(
              titulo: 'Resultado líquido',
              valor: _fmtMoeda.format(extrato.resultadoLiquido),
              cor: resultadoCor,
            ),
          ],
        ),
      ],
    ),
  );
}

pw.Widget _blocoResumo({
  required String titulo,
  required String valor,
  required PdfColor cor,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _t(titulo, size: 8, color: PdfColors.grey700),
      pw.SizedBox(height: 2),
      _t(valor, size: 12, bold: true, color: cor),
    ],
  );
}

pw.Widget _blocoFinanceiro({
  required String titulo,
  required String valor,
  required PdfColor cor,
}) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      _t(titulo, size: 8, color: PdfColors.grey700),
      pw.SizedBox(height: 2),
      _t(valor, size: 12, bold: true, color: cor),
    ],
  );
}



  // ── Nota fiscal ──────────────────────────────────────────────────────────

  pw.Widget _notaFiscal() {
    return pw.Center(
      child: _t(
        'Documento processado por computador através do Sistema de Facturação Stech ERP.',
        size: 7,
        color: PdfColors.grey600,
      ),
    );
  }

  // ── Rodapé de página ─────────────────────────────────────────────────────

  pw.Widget _rodapePagina(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _t('Stech Engenharia © ${DateTime.now().year}',
            size: 7, color: PdfColors.grey600),
        _t('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            size: 7, color: PdfColors.grey600),
      ],
    );
  }

  // ── Salvar ───────────────────────────────────────────────────────────────

  Future<File> _salvar(pw.Document pdf, ExtratoModel extrato) async {
    final nome = 'EXTRATO-${_fmtNomeArq.format(DateTime.now())}.pdf';
    final dir  = await _resolveDirectory();
    final file = File('${dir.path}/$nome');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<Directory> _resolveDirectory() async {
    try {
      if (Platform.isAndroid) {
        final d = Directory('/storage/emulated/0/Download/');
        if (await d.exists()) return d;
        final ext = await getExternalStorageDirectory();
        if (ext != null) {
          final d2 = Directory('${ext.path}/Downloads');
          if (!await d2.exists()) await d2.create(recursive: true);
          return d2;
        }
      } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        final dl = await getDownloadsDirectory();
        if (dl != null) return dl;
      }
    } catch (_) {}
    return getApplicationDocumentsDirectory();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  pw.Widget _t(
    String text, {
    double size = 10,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: size,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    );
  }

  pw.Widget _thCell(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  pw.Widget _tdCell(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  String _statusLabelPdf(String status) {
  switch (status.toUpperCase()) {
    case 'PAGO':
      return 'Pago';
    case 'PARCIAL':
      return 'Parcial';
    case 'PENDENTE':
      return 'Pendente';
    default:
      return status;
  }
}

}