import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/extrato_model.dart';

const _kAzul = PdfColor.fromInt(0xFF1B2A6B);
const _kVermelho = PdfColor.fromInt(0xFFC8102E);

class ExtratoPdfInternoService {
  static final ExtratoPdfInternoService instance = ExtratoPdfInternoService._();
  ExtratoPdfInternoService._();

  final _fmtData = DateFormat('dd/MM/yyyy');
  final _fmtNomeArq = DateFormat('yyyyMMdd_HHmm');

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

  Future<pw.Document> _build(ExtratoModel extrato) async {
    final iconBytes = await rootBundle.load('assets/icon/app_icon.png');
    final iconImage = pw.MemoryImage(iconBytes.buffer.asUint8List());

    final doc = pw.Document(
      title: 'Extracto Interno ${extrato.labelPeriodo}',
      author: 'Stech Engenharia',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(30, 28, 30, 20),
        footer: (ctx) => _rodapePagina(ctx),
        build: (ctx) => [
          _cabecalho(extrato, iconImage),
          pw.SizedBox(height: 18),
          _tabela(extrato),
          pw.SizedBox(height: 18),
          _resumo(extrato),
          pw.SizedBox(height: 10),
          _nota(),
        ],
      ),
    );

    return doc;
  }

  pw.Widget _cabecalho(ExtratoModel extrato, pw.MemoryImage icon) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Image(icon, width: 150, height: 80, fit: pw.BoxFit.contain),
                  pw.SizedBox(height: 6),
                  _t('Segurança Tecnologica SU, LDA (Stech Engenharia)',
                      bold: true, size: 8.5),
                  _t('Bairro: Chingodzi, Tete', size: 8),
                  _t('Número: +258 84 239 0756 ou 87 939 0756', size: 8),
                  _t('Email: info@stech.co.mz', size: 8),
                  _t('Website: www.stecheng.co.mz', size: 8),
                  _t('NUIT: 401 684 530', size: 8),
                ],
              ),
            ),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _t(
                    'EXTRACTO DE DOCUMENTOS FISCAIS',
                    size: 16,
                    bold: true,
                    color: _kAzul,
                    align: pw.TextAlign.right,
                  ),
                  pw.SizedBox(height: 6),
                  _t(
                    'Período: ${_fmtData.format(extrato.dataInicio)} a ${_fmtData.format(extrato.dataFim)}',
                    size: 9,
                    color: PdfColors.grey700,
                    align: pw.TextAlign.right,
                  ),
                  _t(
                    'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now())}',
                    size: 8,
                    color: PdfColors.grey600,
                    align: pw.TextAlign.right,
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 18),
        pw.Divider(color: _kAzul, thickness: 2),
      ],
    );
  }

/// Cor de destaque para a linha de ajuste (Nota de Crédito/Débito)
  /// associada a uma factura, igual à usada no ExtratoPdfService.
  static const _kAjusteCor = PdfColor.fromInt(0xFFB45309); // laranja escuro

  pw.Widget _tabela(ExtratoModel extrato) {
    final linhas = extrato.linhas;

    const estiloCell = pw.TextStyle(fontSize: 8);
    final estiloBold = pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold);
    final estiloHeader = pw.TextStyle(
      fontSize: 8,
      color: PdfColors.white,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.45),
      columnWidths: const {
        0: pw.FixedColumnWidth(58),
        1: pw.FixedColumnWidth(82),
        2: pw.FlexColumnWidth(),
        3: pw.FixedColumnWidth(78),
        4: pw.FixedColumnWidth(74),
        5: pw.FixedColumnWidth(58),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _kAzul),
          children: [
            _thCell('Data', estiloHeader),
            _thCell('Documento', estiloHeader),
            _thCell('Empresa', estiloHeader),
            _thCell('NUIT', estiloHeader),
            _thCell('Valor Total', estiloHeader, align: pw.TextAlign.right),
            _thCell('Estado', estiloHeader, align: pw.TextAlign.center),
          ],
        ),
        for (int i = 0; i < linhas.length; i++)
          _linhaTabela(linhas[i], i, estiloCell, estiloBold),
      ],
    );
  }

  pw.TableRow _linhaTabela(
    LinhaExtrato linha,
    int indice,
    pw.TextStyle estiloCell,
    pw.TextStyle estiloBold,
  ) {
    if (linha.isAjusteNotaRetificativa) {
      final estiloAjuste = pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: _kAjusteCor,
        fontStyle: pw.FontStyle.italic,
      );

return pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.orange50),
        children: [
          _tdCell(_fmtData.format(linha.dataEmissao), estiloAjuste),
          _tdCell(linha.numeroDocumento, estiloAjuste),
          _tdCell(linha.nomeEmpresa, estiloAjuste),
          _tdCell('-', estiloAjuste),
          _tdCell(
            '${_fmtNumero(linha.valorTotal)} MZN',
            estiloAjuste,
            align: pw.TextAlign.right,
          ),
          _tdCell('-', estiloAjuste, align: pw.TextAlign.center),
        ],
      );
    }

    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: indice.isOdd ? PdfColors.grey100 : PdfColors.white,
      ),
      children: [
        _tdCell(_fmtData.format(linha.dataEmissao), estiloCell),
        _tdCell(linha.numeroDocumento, estiloBold),
        _tdCell(linha.nomeEmpresa, estiloCell),
        _tdCell(linha.nuit ?? '-', estiloCell),
        _tdCell(
          '${_fmtNumero(linha.valorTotal)} MZN',
          estiloCell,
          align: pw.TextAlign.right,
        ),
        _tdCell(
          linha.estado,
          linha.estado.toUpperCase() == 'ANULADO'
              ? pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _kVermelho,
                )
              : estiloCell,
          align: pw.TextAlign.center,
        ),
      ],
    );
  }

pw.Widget _resumo(ExtratoModel extrato) {
  final totalDocumentosValidos = _totalDocumentosValidos(extrato);
  final somaTotalValida = _somaTotalValida(extrato);

  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: PdfColors.grey100,
      border: pw.Border.all(color: PdfColors.grey300, width: 0.6),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _t('Período considerado:', size: 8, color: PdfColors.grey700),
            _t(
              '${_fmtData.format(extrato.dataInicio)} a ${_fmtData.format(extrato.dataFim)}',
              size: 9,
              bold: true,
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _t('Total de documentos:', size: 8, color: PdfColors.grey700),
            _t(
              '$totalDocumentosValidos',
              size: 13,
              bold: true,
              color: _kAzul,
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _t('Soma total:', size: 8, color: PdfColors.grey700),
            _t(
              '${_fmtNumero(somaTotalValida)} MZN',
              size: 13,
              bold: true,
              color: _kVermelho,
            ),
          ],
        ),
      ],
    ),
  );
}



  pw.Widget _nota() {
    return pw.Center(
      child: _t(
        'Documento processado por computador através do Sistema de Facturação Stech ERP.',
        size: 7,
        color: PdfColors.grey600,
      ),
    );
  }

  pw.Widget _rodapePagina(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _t('Stech Engenharia (c) ${DateTime.now().year}',
            size: 7, color: PdfColors.grey600),
        _t('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
            size: 7, color: PdfColors.grey600),
      ],
    );
  }

  Future<File> _salvar(pw.Document pdf, ExtratoModel extrato) async {
    final nome =
        'EXTRACTO_INTERNO-${_fmtNomeArq.format(DateTime.now())}.pdf';

    final dir = await _resolveDirectory();
    final file = File('${dir.path}/$nome');

    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<Directory> _resolveDirectory() async {
    try {
      if (Platform.isAndroid) {
        final d = Directory('/storage/emulated/0/Download/');
        if (await d.exists()) return d;
      }

      final dl = await getDownloadsDirectory();
      if (dl != null) return dl;
    } catch (_) {}

    return getApplicationDocumentsDirectory();
  }

  String _fmtNumero(double valor) {
    return NumberFormat('#,##0.00', 'pt_PT').format(valor);
  }

  bool _linhaAnulada(LinhaExtrato linha) {
  return linha.estado.trim().toUpperCase() == 'ANULADO';
}

List<LinhaExtrato> _linhasValidas(ExtratoModel extrato) {
  return extrato.linhas.where((linha) => !_linhaAnulada(linha)).toList();
}

int _totalDocumentosValidos(ExtratoModel extrato) {
  return _linhasValidas(extrato).length;
}

double _somaTotalValida(ExtratoModel extrato) {
  return _linhasValidas(extrato).fold<double>(
    0.0,
    (soma, linha) => soma + linha.valorTotal,
  );
}



  pw.Widget _t(
    String text, {
    double size = 10,
    bool bold = false,
    PdfColor? color,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Text(
      text,
      textAlign: align,
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }

  pw.Widget _tdCell(
    String text,
    pw.TextStyle style, {
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: pw.Text(text, style: style, textAlign: align),
    );
  }
}