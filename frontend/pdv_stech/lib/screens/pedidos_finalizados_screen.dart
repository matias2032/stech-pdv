// lib/screens/pedidos_finalizados_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:api_compartilhado/api_compartilhado.dart';
import 'package:api_compartilhado/services/pdf_service.dart';
import '../widgets/app_sidebar.dart';
import 'package:http/http.dart' as http;
import 'package:api_compartilhado/api_config.dart';
import 'package:provider/provider.dart';

// ─── Paleta ──────────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF1B2A6B);
const _kAccent     = Color(0xFFC8102E);
const _kBackground = Color(0xFFF4F5F7);
const _kSuccess    = Color(0xFF2E7D32);

class PedidosFinalizadosScreen extends StatefulWidget {
  const PedidosFinalizadosScreen({super.key});

  @override
  State<PedidosFinalizadosScreen> createState() =>
      _PedidosFinalizadosScreenState();
      
}

class _PedidosFinalizadosScreenState extends State<PedidosFinalizadosScreen>
    with SingleTickerProviderStateMixin {

  final _currencyFmt   = NumberFormat.currency(locale: 'pt_PT', symbol: 'MZN');
  final _dateFmt       = DateFormat('dd/MM/yyyy HH:mm');
  final _pdfService = PdfService.instance;
   final Map<int, String> _tiposPagamento = {};


  String            _pesquisa   = '';


  late final AnimationController _entradaCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;


  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _entradaCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim  = CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entradaCtrl, curve: Curves.easeOutCubic));

WidgetsBinding.instance.addPostFrameCallback((_) {
  context.read<PedidoProvider>().carregarTiposPagamento();
  context.read<PedidoProvider>().listarPorStatus('finalizado');
});
  }

@override
void dispose() {
  _entradaCtrl.dispose();
  _searchCtrl.dispose();
  super.dispose();
}

  // ── Lógica ───────────────────────────────────────────────────────────────

    
Future<void> _carregar() async {
  await Future.wait([
    context.read<PedidoProvider>().listarPorStatus('finalizado'),
    context.read<PedidoProvider>().carregarTiposPagamento(),
  ]);

  if (!mounted) return;

  final provider = context.read<PedidoProvider>();

  if (provider.errorMessage != null) {
    _snack('Erro ao carregar pedidos: ${provider.errorMessage}', _kAccent);
    return;
  }

  // Actualiza o cache local de tipos de pagamento
  setState(() {
    for (final t in provider.tiposPagamento) {
      _tiposPagamento[t.idTipoPagamento] = t.tipoPagamento;
    }
    // Reinicia o filtro com os dados novos
    _filtrar(_pesquisa);
  });

  _entradaCtrl.forward(from: 0);
}

void _filtrar(String valor) {
  setState(() {
    _pesquisa = valor.toLowerCase();
    // lê directamente do Provider — sem variável local
  });
}

  void _snack(String msg, Color cor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: cor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  // ── Totais ────────────────────────────────────────────────────────────────





  // ── Build ─────────────────────────────────────────────────────────────────

@override
Widget build(BuildContext context) {
  final provider = context.watch<PedidoProvider>();

  // Filtragem calculada na hora a partir do Provider
  final filtrados = provider.pedidos.where((p) {
    return p.referencia.toLowerCase().contains(_pesquisa) ||
        _currencyFmt.format(p.total).toLowerCase().contains(_pesquisa);
  }).toList();

  final totalGeral = filtrados.fold(0.0, (acc, p) => acc + p.total);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _kBackground,
        drawer: const AppSidebar(currentRoute: '/pedidos_finalizados'),
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
  child: provider.isLoading 
                        ? _buildLoading()
                        : Column(
                            children: [
_buildResumo(filtrados, totalGeral),
                              _buildBarraPesquisa(),
Expanded(child: _buildLista(filtrados)),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      color: _kPrimary,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.menu_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pedidos Finalizados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.4,
                  ),
                ),
                Text(
                  'Histórico de vendas concluídas',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          _HeaderIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualizar',
            cor: Colors.white,
            onTap: _carregar,
          ),
        ],
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28, height: 28,
            child: CircularProgressIndicator(color: _kPrimary, strokeWidth: 2.5),
          ),
          SizedBox(height: 14),
          Text('A carregar pedidos…',
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  // ── Resumo ────────────────────────────────────────────────────────────────

Widget _buildResumo(List<PedidoModel> filtrados, double totalGeral) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _ResumoCard(
              icone: Icons.receipt_long_outlined,
              label: 'Total de pedidos',
  valor: '${filtrados.length}',
              cor: _kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ResumoCard(
              icone: Icons.payments_outlined,
              label: 'Valor total',
  valor: _currencyFmt.format(totalGeral), 
              cor: _kSuccess,
            ),
          ),
        ],
      ),
    );
  }

  // ── Barra de pesquisa ─────────────────────────────────────────────────────

  Widget _buildBarraPesquisa() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _filtrar,
        decoration: InputDecoration(
          hintText: 'Pesquisar por referência…',
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _pesquisa.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    _filtrar('');
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ── Lista ─────────────────────────────────────────────────────────────────

Widget _buildLista(List<PedidoModel> filtrados) {
  if (filtrados.isEmpty) return _buildListaVazia(); 

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
itemCount: filtrados.length,       
      separatorBuilder: (_, __) => const SizedBox(height: 10),
itemBuilder: (_, i) => _PedidoCard(
      pedido: filtrados[i],    
  currencyFmt: _currencyFmt,
  dateFmt: _dateFmt,
  tipoPagamento: _tiposPagamento[filtrados[i].idTipoPagamento] ?? 'Desconhecido',
  pdfService: _pdfService,
),
    );
  }

  Widget _buildListaVazia() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_outlined, color: Colors.grey, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Nenhum pedido encontrado',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
          const SizedBox(height: 6),
          Text(
            _pesquisa.isNotEmpty
                ? 'Tente outro termo de pesquisa'
                : 'Ainda não há pedidos finalizados',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ─── Card de pedido ───────────────────────────────────────────────────────────

class _PedidoCard extends StatefulWidget {
  final PedidoModel  pedido;
  final NumberFormat currencyFmt;
  final DateFormat   dateFmt;
  final String       tipoPagamento;
  final PdfService   pdfService;

  const _PedidoCard({
    required this.pedido,
    required this.currencyFmt,
    required this.dateFmt,
    required this.tipoPagamento,
    required this.pdfService,
  });

  @override
  State<_PedidoCard> createState() => _PedidoCardState();
}

class _PedidoCardState extends State<_PedidoCard> {
  bool _expandido = false;
    bool _imprimindo = false;
  ClienteModel? _cliente;            // ← aqui
  bool _carregandoCliente = false;   // ← aqui

  PedidoModel get p => widget.pedido;

   // ← aqui — usa p que é getter local
  Future<void> _carregarCliente() async {
    if (_cliente != null || p.idCliente == null) return;
    setState(() => _carregandoCliente = true);
    try {
      final service = ClienteService(
        baseUrl:    ApiConfig.baseUrl,
        httpClient: http.Client(),
      );
      final cliente = await service.buscarPorId(p.idCliente!);
      if (mounted) setState(() => _cliente = cliente);
    } catch (_) {
      // silencioso
    } finally {
      if (mounted) setState(() => _carregandoCliente = false);
    }
  }


      Future<void> _imprimir(BuildContext context) async {
  if (_imprimindo) return;
  setState(() => _imprimindo = true);
  try {
    final file = await widget.pdfService.gerarComprovativo(
      pedido: p,
      tipoPagamento: widget.tipoPagamento,
      paperFormat: PaperFormat.a4,
    );
    await widget.pdfService.abrirPdf(file);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro ao gerar factura: $e'),
        backgroundColor: _kAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  } finally {
    if (mounted) setState(() => _imprimindo = false);
  }
}
  

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: _expandido
              ? _kPrimary.withOpacity(0.35)
              : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          // ── Cabeçalho sempre visível ──
InkWell(
  onTap: () {
    setState(() => _expandido = !_expandido);
    if (_expandido) _carregarCliente(); // carrega ao abrir
  },
  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Ícone
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: _kSuccess.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded,
                        color: _kSuccess, size: 22),
                  ),
                  const SizedBox(width: 12),
                  // Referência + data
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.referencia,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _kPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.dateFmt.format(
                              p.dataFinalizacao ?? p.dataPedido),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  // Total
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.currencyFmt.format(p.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: _kPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: _kSuccess.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text(
                          'FINALIZADO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: _kSuccess,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
               const SizedBox(width: 4),
                  _imprimindo
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kPrimary))
                      : IconButton(
                          icon: const Icon(Icons.print_outlined,
                              color: _kPrimary, size: 20),
                          tooltip: 'Imprimir factura',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _imprimir(context),
                        ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expandido ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        color: Colors.grey, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // ── Detalhe expansível ──
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expandido ? _buildDetalhe() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildDetalhe() {

    
    return Container(
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.03),
        borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(14)),
        border: Border(
            top: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Cliente ──────────────────────────────────────────────────
if (p.idCliente != null) ...[
  _labelSeccao('Cliente', Icons.business_outlined),
  const SizedBox(height: 6),
  _carregandoCliente
      ? const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            height: 16, width: 16,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: _kPrimary),
          ),
        )
      : _cliente == null
          ? Text('ID: ${p.idCliente}',
              style: const TextStyle(fontSize: 13, color: Colors.grey))
          : Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: _kPrimary.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.business_rounded,
                      size: 15, color: _kPrimary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _cliente!.nomeCompleto,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                        if (_cliente!.contacto != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _cliente!.contacto!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
  const SizedBox(height: 10),
],
          // Itens de produto
          if (p.itensProduto.isNotEmpty) ...[
            _labelSeccao('Produtos', Icons.inventory_2_outlined),
            const SizedBox(height: 6),
            ...p.itensProduto.map(_buildItemProduto),
            const SizedBox(height: 10),
          ],

          // Itens de serviço
          if (p.itensServico.isNotEmpty) ...[
            _labelSeccao('Serviços', Icons.miscellaneous_services_outlined),
            const SizedBox(height: 6),
            ...p.itensServico.map(_buildItemServico),
            const SizedBox(height: 10),
          ],

          const Divider(height: 16),

          // Pagamento
          _infoRow('Valor pago',
              widget.currencyFmt.format(p.valorPago)),
          if (p.troco != null && p.troco! > 0) ...[
            const SizedBox(height: 4),
            _infoRow('Troco',
                widget.currencyFmt.format(p.troco!),
                cor: _kSuccess),
          ],
          const SizedBox(height: 4),
          _infoRow('Total',
              widget.currencyFmt.format(p.total),
              negrito: true),

          // Observações
          if (p.observacoes != null &&
              p.observacoes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined,
                      size: 15, color: Colors.grey),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      p.observacoes!,
                      style: const TextStyle(
                          fontSize: 12, color: Colors.black54, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemProduto(ItemPedidoModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantidade}×',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _kPrimary),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(item.nomeProduto,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
          Text(
            widget.currencyFmt.format(item.subtotal),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildItemServico(ItemPedidoServicoModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                '${item.quantidade}×',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: _kAccent),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.nomeServico ?? 'Serviço',
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Text(
            widget.currencyFmt.format(item.subtotal),
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _labelSeccao(String texto, IconData icon) {
    return Row(children: [
      Icon(icon, size: 13, color: _kPrimary.withOpacity(0.6)),
      const SizedBox(width: 5),
      Text(
        texto.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: _kPrimary.withOpacity(0.6),
          letterSpacing: 0.8,
        ),
      ),
    ]);
  }

  Widget _infoRow(String label, String valor,
      {bool negrito = false, Color? cor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600])),
        Text(
          valor,
          style: TextStyle(
            fontSize: negrito ? 15 : 13,
            fontWeight: negrito ? FontWeight.w800 : FontWeight.w500,
            color: cor ?? (negrito ? _kPrimary : Colors.black87),
          ),
        ),
      ],
    );
  }
}

// ─── Card de resumo ───────────────────────────────────────────────────────────

class _ResumoCard extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   valor;
  final Color    cor;

  const _ResumoCard({
    required this.icone,
    required this.label,
    required this.valor,
    required this.cor,
  }) : icon = icone;

  final IconData icone;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: cor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cor, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text(valor,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: cor,
                      ),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Botão de ícone no header ─────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData     icon;
  final String       tooltip;
  final Color        cor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: cor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cor.withOpacity(0.3)),
          ),
          child: Icon(icon, color: cor, size: 18),
        ),
      ),
    );
  }
}