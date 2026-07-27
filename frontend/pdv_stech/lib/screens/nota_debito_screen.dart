// lib/screens/nota_debito_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

// ─── Paleta (igual às telas de pedidos) ───────────────────────────────────────
const _kPrimary = Color(0xFF1B2A6B);
const _kAccent = Color(0xFFC8102E);
const _kBackground = Color(0xFFF4F5F7);
const _kSuccess = Color(0xFF2E7D32);

class NotaDebitoScreen extends StatefulWidget {
  /// Documento fiscal (FAT/VD) sobre o qual a Nota de Débito será emitida.
  final int idDocumentoOrigem;

  /// Referência do documento de origem, usada apenas para contexto no
  /// cabeçalho. Opcional.
  final String? referenciaDocumento;

  /// Total do pedido/documento de origem, usado apenas para contexto no
  /// cabeçalho. Opcional.
  final double? totalReferencia;

  const NotaDebitoScreen({
    super.key,
    required this.idDocumentoOrigem,
    this.referenciaDocumento,
    this.totalReferencia,
  });

  @override
  State<NotaDebitoScreen> createState() => _NotaDebitoScreenState();
}

class _NotaDebitoScreenState extends State<NotaDebitoScreen> {
  final _currencyFmt = NumberFormat.currency(locale: 'pt_PT', symbol: 'MZN');
  final _valorCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  static const _motivos = [
    (codigo: 'IVA_INCORRETO', label: 'IVA Incorrecto'),
    (codigo: 'OUTRO', label: 'Outro'),
  ];

  String _motivo = 'IVA_INCORRETO';
  bool _enviando = false;

  NotaRetificativaResponseModel? _resultado;

  @override
  void dispose() {
    _valorCtrl.dispose();
    _obsCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  // AÇÃO
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _emitir() async {
    if (_enviando) return;

    final valor = double.tryParse(_valorCtrl.text.replaceAll(',', '.')) ?? 0;
    if (valor <= 0) {
      _snack('Informe um valor válido, maior que zero.', _kAccent);
      return;
    }

    setState(() => _enviando = true);

    try {
      final resultado = await context.read<DocumentoFiscalProvider>().emitirNotaRetificativa(
            idDocumentoOrigem: widget.idDocumentoOrigem,
            codigoTipo: 'NDB',
            idUsuario: SessaoService.instance.idUsuario,
            codigoAt: FiscalConstants.codigoAT,
            motivo: _motivo,
            valor: valor,
            observacoes:
                _obsCtrl.text.trim().isEmpty ? null : _obsCtrl.text.trim(),
          );

      if (!mounted) return;

      setState(() {
        _resultado = resultado;
        _enviando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      _snack('Erro ao emitir Nota de Débito: $e', _kAccent);
    }
  }

  void _snack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: cor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Nota de Débito',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
      ),
      body: _resultado != null ? _buildResultado() : _buildFormulario(),
    );
  }

  Widget _buildFormulario() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _buildCabecalho(),
        const SizedBox(height: 14),
        _buildCampoMotivo(),
        const SizedBox(height: 14),
        _buildCampoValor(),
        const SizedBox(height: 14),
        _buildCampoObservacoes(),
        const SizedBox(height: 24),
        _buildBotaoEmitir(),
      ],
    );
  }

  Widget _buildCabecalho() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.request_page_outlined,
                  color: _kPrimary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.referenciaDocumento ??
                        'Documento #${widget.idDocumentoOrigem}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _kPrimary,
                    ),
                  ),
                  if (widget.totalReferencia != null)
                    Text(
                      'Total do documento: ${_currencyFmt.format(widget.totalReferencia)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoMotivo() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Motivo',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _motivo,
              decoration: InputDecoration(
                filled: true,
                fillColor: _kBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              items: _motivos
                  .map((m) => DropdownMenuItem<String>(
                        value: m.codigo,
                        child: Text(m.label),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _motivo = v);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoValor() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Valor',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valorCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: 'MZN  ',
                filled: true,
                fillColor: _kBackground,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampoObservacoes() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Observações (opcional)',
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _obsCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Detalhes adicionais sobre o débito...',
                filled: true,
                fillColor: _kBackground,
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoEmitir() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _enviando ? null : _emitir,
        icon: _enviando
            ? const SizedBox(
                width: 18,
                height: 18,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.request_page_outlined),
        label: Text(_enviando ? 'A emitir...' : 'Emitir Nota de Débito'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildResultado() {
    final r = _resultado!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: _kSuccess, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Nota de Débito emitida',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold, color: _kPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              r.documento.referencia,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Valor: ${_currencyFmt.format(r.valor)}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _gerarPdfNotaDebito(r),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Gerar PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kAccent,
                  side: const BorderSide(color: _kAccent),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, r),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _kPrimary,
                  side: const BorderSide(color: _kPrimary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Concluir'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _gerarPdfNotaDebito(NotaRetificativaResponseModel r) async {
    try {
      final pdfDoc = NotaRetificativaPdfModel.deApiModel(
        apiModel: r,
        referenciaDocumentoOrigem:
            widget.referenciaDocumento ?? 'Documento #${widget.idDocumentoOrigem}',
      );
      final file = await PdfService.instance.gerarNotaRetificativa(pdfDoc);
      await PdfService.instance.abrirPdf(file);
    } catch (e) {
      _snack('Erro ao gerar PDF: $e', _kAccent);
    }
  }
}