// lib/screens/pedidos_abertos.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:api_compartilhado/services/pdf_service.dart';
import 'finalizar_pedido.dart';

// ─── Paleta (igual a detalhes_produto.dart) ───────────────────────────────────
const _kPrimary    = Color(0xFF1B2A6B);
const _kAccent     = Color(0xFFC8102E);
const _kBackground = Color(0xFFF4F5F7);

class PedidosAbertosScreen extends StatefulWidget {
  const PedidosAbertosScreen({Key? key}) : super(key: key);

  @override
  State<PedidosAbertosScreen> createState() => _PedidosAbertosScreenState();
}

class _PedidosAbertosScreenState extends State<PedidosAbertosScreen> {
  final _pedidoService = PedidoService();
  final _currencyFmt   = NumberFormat.currency(locale: 'pt_PT', symbol: 'MZN');

  List<PedidoModel> _pedidos = [];
  bool _isLoading = true;
  String? _erro;
  bool _operacaoEmAndamento = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // DADOS
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _carregar() async {
    setState(() { _isLoading = true; _erro = null; });
    try {
      final lista = await _pedidoService.listarPorStatus('aberto');
      if (mounted) setState(() { _pedidos = lista; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _erro = 'Erro ao carregar: $e'; _isLoading = false; });
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACÇÕES
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _cancelarPedido(PedidoModel pedido) async {
    if (_operacaoEmAndamento) return;
    final ok = await _dialogoCancelamento(pedido);
    if (!ok) return;

    setState(() => _operacaoEmAndamento = true);
    try {
      await _pedidoService.cancelarPedido(
        pedido.idPedido,
        CancelamentoPedidoRequestDTO(
          idUsuarioCancelou: SessaoService.instance.idUsuario,
          motivo: 'Cancelado pelo operador',
        ),
      );
      if (PedidoAtivoController.instance.pedidoAtivo.value?.idPedido ==
          pedido.idPedido) {
        PedidoAtivoController.instance.limpar();
      }
      _snack('Pedido ${pedido.referencia} cancelado', Colors.orange);
      await _carregar();
    } catch (e) {
      _snack('Erro ao cancelar: $e', _kAccent);
    } finally {
      if (mounted) setState(() => _operacaoEmAndamento = false);
    }
  }

  Future<void> _abrirFinalizar(PedidoModel pedido) async {
    final finalizado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FinalizarPedidoScreen(pedido: pedido)),
    );
    if (finalizado == true && mounted) {
      PedidoAtivoController.instance.limpar();
      await _carregar();
    }
  }

  Future<bool> _dialogoCancelamento(PedidoModel pedido) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Cancelar Pedido',
                style: TextStyle(color: _kPrimary, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pedido.referencia,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: _kPrimary)),
                const SizedBox(height: 6),
                _dialogRow('Total', _currencyFmt.format(pedido.total)),
                _dialogRow('Itens',
                    '${pedido.itensProduto.length + pedido.itensServico.length}'),
                const SizedBox(height: 12),
                _infoBox(
                  icon: Icons.warning_amber,
                  texto: 'O estoque será restaurado automaticamente.',
                  cor: Colors.orange,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Voltar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Cancelar Pedido'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildBody()),
        ],
      ),
    );
  }

  // ─── SliverAppBar (padrão detalhes_produto) ────────────────────────────────

  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      expandedHeight: 120,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Atualizar',
          onPressed: _isLoading ? null : _carregar,
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_kPrimary, _kPrimary.withBlue(140)],
            ),
          ),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.pending_actions, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pedidos Abertos',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(
                        _isLoading
                            ? 'A carregar…'
                            : '${_pedidos.length} pedido(s)',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75), fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Corpo ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _kPrimary),
              SizedBox(height: 16),
              Text('A carregar pedidos…', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_erro != null) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: _kAccent),
                const SizedBox(height: 16),
                Text(_erro!, textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _carregar,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                  style: ElevatedButton.styleFrom(backgroundColor: _kPrimary,
                      foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_pedidos.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('Nenhum pedido aberto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Colors.grey[500])),
              const SizedBox(height: 8),
              Text('Todos os pedidos foram finalizados.',
                  style: TextStyle(color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _carregar,
      color: _kAccent,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: _pedidos.length,
        itemBuilder: (_, i) => _buildCard(_pedidos[i]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CARD DO PEDIDO
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCard(PedidoModel pedido) {
    final isAtivo = PedidoAtivoController.instance.pedidoAtivo.value?.idPedido ==
        pedido.idPedido;
    final totalItens =
        pedido.itensProduto.length + pedido.itensServico.length;

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isAtivo ? Colors.green.shade400 : Colors.grey.shade200,
          width: isAtivo ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_outlined,
                      color: _kPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pedido.referencia,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: _kPrimary)),
                      const SizedBox(height: 3),
                      Text(_formatarData(pedido.dataPedido),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                ),
                // Badge "Aberto"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.radio_button_on, size: 10, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text('Aberto',
                        style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ]),
                ),
              ],
            ),

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 14),

            // ── Itens de produto ───────────────────────────────────────────
            if (pedido.itensProduto.isNotEmpty) ...[
              _sectionLabel(Icons.inventory_2_outlined, 'Produtos'),
              const SizedBox(height: 8),
              ...pedido.itensProduto.map(_buildLinhaItemProduto),
            ],

            // ── Itens de serviço ───────────────────────────────────────────
            if (pedido.itensServico.isNotEmpty) ...[
              const SizedBox(height: 10),
              _sectionLabel(Icons.miscellaneous_services_outlined, 'Serviços'),
              const SizedBox(height: 8),
              ...pedido.itensServico.map(_buildLinhaItemServico),
            ],

            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey[200]),
            const SizedBox(height: 12),

            // ── Rodapé: resumo + acções ────────────────────────────────────
            _buildRodape(pedido, totalItens),
          ],
        ),
      ),
    );
  }

  // ─── Label de secção ──────────────────────────────────────────────────────

  Widget _sectionLabel(IconData icon, String texto) {
    return Row(children: [
      Icon(icon, size: 14, color: _kPrimary.withOpacity(0.5)),
      const SizedBox(width: 6),
      Text(texto,
          style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600])),
    ]);
  }

  // ─── Linha de item de produto ─────────────────────────────────────────────

  Widget _buildLinhaItemProduto(ItemPedidoModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _kPrimary.withOpacity(0.07),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('${item.quantidade}×',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(item.nomeProduto,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis),
        ),
        Text(
          _currencyFmt.format(item.subtotal),
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
        ),
      ]),
    );
  }

  // ─── Linha de item de serviço ─────────────────────────────────────────────

  Widget _buildLinhaItemServico(ItemPedidoServicoModel item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.07),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text('${item.quantidade}×',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.nomeServico ?? 'Serviço #${item.idServico}',
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              if (item.observacoes != null && item.observacoes!.isNotEmpty)
                Text(item.observacoes!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Text(
          _currencyFmt.format(item.subtotal),
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: _kPrimary),
        ),
      ]),
    );
  }

  // ─── Rodapé do card ───────────────────────────────────────────────────────

  Widget _buildRodape(PedidoModel pedido, int totalItens) {
    return Row(
      children: [
        // Cancelar
        OutlinedButton.icon(
          onPressed:
              _operacaoEmAndamento ? null : () => _cancelarPedido(pedido),
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Cancelar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _kAccent,
            side: BorderSide(color: _kAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const Spacer(),
        // Total
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$totalItens item(s)',
                style: TextStyle(color: Colors.grey[500], fontSize: 11)),
            Text(
              _currencyFmt.format(pedido.total),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kPrimary),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Finalizar
        ElevatedButton.icon(
          onPressed:
              _operacaoEmAndamento ? null : () => _abrirFinalizar(pedido),
          icon: const Icon(Icons.check, size: 18),
          label: const Text('Finalizar',
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // HELPERS DE DIÁLOGO (padrão detalhes_produto)
  // ──────────────────────────────────────────────────────────────────────────

  Widget _infoBox({required IconData icon, required String texto, required Color cor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cor.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.25)),
      ),
      child: Row(children: [
        Icon(icon, size: 16, color: cor),
        const SizedBox(width: 8),
        Expanded(child: Text(texto, style: TextStyle(fontSize: 12, color: cor))),
      ]),
    );
  }

  Widget _dialogRow(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(valor,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
        ],
      ),
    );
  }

  String _formatarData(DateTime data) {
    final diff = DateTime.now().difference(data);
    if (diff.inMinutes < 60) return 'Há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Há ${diff.inHours}h';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} '
        '${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }
}