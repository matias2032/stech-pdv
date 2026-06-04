import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

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

  // ── Rodapé de totais ─────────────────────────────────────────────────────

  pw.Widget _rodapeTotais(ExtratoModel extrato) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _t('Período considerado:', size: 8, color: PdfColors.grey700),
              pw.SizedBox(height: 2),
              _t(
                '${_fmtData.format(extrato.dataInicio)}'
                ' → ${_fmtData.format(extrato.dataFim)}',
                size: 9,
                bold: true,
              ),
            ],
          ),
          pw.Row(
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _t('Total de documentos:', size: 8, color: PdfColors.grey700),
                  pw.SizedBox(height: 2),
                  _t(
                    '${extrato.totalDocumentos}',
                    size: 12,
                    bold: true,
                    color: _kAzul,
                  ),
                ],
              ),
              pw.SizedBox(width: 32),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _t('Soma total:', size: 8, color: PdfColors.grey700),
                  pw.SizedBox(height: 2),
                  _t(
                    _fmtMoeda.format(extrato.somaTotal),
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
}