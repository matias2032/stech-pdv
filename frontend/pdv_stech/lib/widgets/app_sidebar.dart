// lib/widgets/app_sidebar.dart

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:api_compartilhado/api_compartilhado.dart';
import '../widgets/estoque_badge.dart';
import 'dart:io';

// TODO: Descomentar quando servico_logs for migrado para Spring Boot
// import '../services/servico_logs.dart';

const _kVermelho = Color(0xFFC8102E);
const _kAzul = Color.fromARGB(255, 27, 42, 107);
const _kBranco = Colors.white;
const _kCinzaClaro = Color(0xFFF4F5F7);
const _kCinzaTexto = Color(0xFF6B7280);

class AppSidebar extends StatefulWidget {
  final String currentRoute;

  const AppSidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  bool _showUserMenu = false;
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;

  // TODO: Reactivar quando pedido_contador_service estiver migrado
  int _contadorPedidos = 0;
  StreamSubscription<int>? _contadorSubscription;
  // final PedidoContadorService _contadorService = PedidoContadorService.instance;

  // Badge de pedidos abertos (catálogo)
  final _pedidoService = PedidoService();
  int _countPedidosAbertos = 0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _carregarPedidosAbertos();
    PedidoAtivoController.instance.pedidoAtivo.addListener(_carregarPedidosAbertos);

    // TODO: Reactivar quando pedido_contador_service estiver migrado
    // _carregarContadorDoUsuario();
    // _contadorPedidos = _contadorService.contadorAtual;
    // _contadorSubscription = _contadorService.contadorStream.listen((novoValor) {
    //   if (mounted) setState(() => _contadorPedidos = novoValor);
    // });
  }

  Future<void> _carregarPedidosAbertos() async {
    try {
      final total = await _pedidoService.contarPedidosAbertos();
      if (mounted) setState(() => _countPedidosAbertos = total);
    } catch (_) {}
  }

  // TODO: Reactivar quando pedido_contador_service estiver migrado
  // Future<void> _carregarContadorDoUsuario() async {
  //   final usuario = SessaoService.instance.usuarioAtual;
  //   if (usuario != null) {
  //     await _contadorService.recarregarSeNecessario();
  //   }
  // }

  @override
  void dispose() {
    _animationController.dispose();
    _contadorSubscription?.cancel();
    PedidoAtivoController.instance.pedidoAtivo.removeListener(_carregarPedidosAbertos);
    super.dispose();
  }

  void _toggleUserMenu() {
    setState(() {
      _showUserMenu = !_showUserMenu;
      if (_showUserMenu) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  bool _temPermissao(String route) {
    return [
      'dashboard',
      '/catalogo',
      '/gerenciar_usuarios',
      '/gerenciar_categorias',
      '/gerenciar_marcas',
      '/gerenciar_servicos',
      '/gerenciar_produtos',
      '/configuracoes_impressora',
      '/pedidos_finalizados',
      '/gerenciar_clientes',
      '/gerenciar_documentos',
         '/gerenciar_extractos',
    ].contains(route);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = SessaoService.instance.usuario;


    if (usuario == null) {
      return const SizedBox.shrink();
    }

    return Drawer(
  child: Column(
    children: [
      Expanded(
        child: ListView(
          padding: EdgeInsets.zero,
      children: [
  _buildDrawerHeader(usuario),

  // ✅ Item único: Todos os perfis veem o Painel de Controle
  _buildMenuItem(
    icon: Icons.dashboard,
    title: 'Painel de Controle',
    route: '/dashboard',
  ),
   
  _buildMenuItemComBadge(
    icon: Icons.shopping_cart,
    title: 'Catálogo',
    route: '/catalogo',
    contador: _countPedidosAbertos,
  ),

  // 🔒 Menus administrativos (Montados de forma limpa e sem duplicados)
  if (usuario.isAdmin) ...[
    _buildMenuItem(
      icon: Icons.manage_accounts,
      title: 'Gerenciar Usuários',
      route: '/gerenciar_usuarios',
    ),
    _buildMenuItem(
      icon: Icons.history,
      title: 'Histórico de Pedidos',
      route: '/pedidos_finalizados',
    ),
    _buildMenuItem(
      icon: Icons.grid_view,
      title: 'Gerenciar Categorias',
      route: '/gerenciar_categorias',
    ),
    _buildMenuItem(
      icon: Icons.label_important_outline,
      title: 'Gerenciar Marcas',
      route: '/gerenciar_marcas',
    ),
    _buildMenuItem(
      icon: Icons.miscellaneous_services,
      title: 'Gerenciar Serviços',
      route: '/gerenciar_servicos',
    ),
    _buildMenuItem(
      icon: Icons.inventory_2_outlined,
      title: 'Gerenciar Produtos',
      route: '/gerenciar_produtos',
      usarBadge: true,
    ),
    _buildMenuItem(
      icon: Icons.contacts_outlined,
      title: 'Gerenciar Clientes',
      route: '/gerenciar_clientes',
      usarBadge: true,
    ),
    _buildMenuItem(
      icon: Icons.description,
      title: 'Facturação',
      route: '/gerenciar_documentos',
      usarBadge: true,
    ),
    _buildMenuItem(
      icon: Icons.assessment,
      title: 'Extractos',
      route: '/gerenciar_extractos',
      usarBadge: true,
    ),
    
    // ✅ Condição de plataforma simplificada (Apenas Desktop/Web vê a impressora se for Admin)
    if (!Platform.isAndroid && !Platform.isIOS)
      _buildMenuItem(
        icon: Icons.print,
        title: 'Configurações da Impressora',
        route: '/configuracoes_impressora',
      ),
  ],

  _buildUserSection(usuario),  // 👈 Fixo no fundo do painel
],
        ),
      ),
    ],  
  ),
);
  }

  Widget _buildDrawerHeader(usuario) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 27, 42, 107),
            Color.fromARGB(255, 17, 26, 66),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(
tag: 'user_avatar_${usuario.id}',
            child: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white,
              child: Text(
                usuario.nome[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 36,
                  color: Color.fromARGB(255, 27, 42, 107),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${usuario.nome} ${usuario.apelido}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              usuario.nomePerfil,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String route,
    bool usarBadge = false,
  }) {
    final isSelected = widget.currentRoute == route;

    Widget iconWidget = Icon(
      icon,
      color: isSelected ? _kAzul : Colors.grey[700],
    );

    // if (usarBadge) {
    //   iconWidget = EstoqueBadge(child: iconWidget);
    // }

    return ListTile(
      leading: iconWidget,
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? _kAzul : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: _kAzul.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  /// Item de menu com badge de contagem (ex.: catálogo — pedidos abertos).
  Widget _buildMenuItemComBadge({
    required IconData icon,
    required String title,
    required String route,
    required int contador,
  }) {
    final isSelected = widget.currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? _kAzul : Colors.grey[700],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? _kAzul : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (contador > 0)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _kVermelho,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: _kVermelho.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                contador > 99 ? '99+' : '$contador',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: _kAzul.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  // TODO: Reactivar quando pedido_contador_service estiver migrado
  Widget _buildMenuItemComContador({
    required IconData icon,
    required String title,
    required String route,
    required int contador,
  }) {
    final isSelected = widget.currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? _kAzul : Colors.grey[700],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? _kAzul : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (contador > 0)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.4),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Text(
                '$contador',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      selected: isSelected,
      selectedTileColor: _kAzul.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: () {
        Navigator.pop(context);
        if (!isSelected) {
          Navigator.pushReplacementNamed(context, route);
        }
      },
    );
  }

  Widget _buildUserSection(usuario) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomCenter,
            child: _showUserMenu
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildUserMenuItem(
                          icon: Icons.person,
                          title: 'Alterar Dados',
                          color: Colors.blue,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/editar_usuario');
                          },
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildUserMenuItem(
                          icon: Icons.lock,
                          title: 'Alterar Senha',
                          color: Colors.orange,
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/alterar_senha');
                          },
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildUserMenuItem(
                          icon: Icons.logout,
                          title: 'Sair',
                          color: Colors.red,
                          onTap: () => _confirmarLogout(context),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleUserMenu,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: _kAzul,
                      child: Text(
                        usuario.nome[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${usuario.nome} ${usuario.apelido}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            usuario.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationAnimation,
                      child: Icon(Icons.expand_less, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(
        title,
        style: TextStyle(
          color: title == 'Sair' ? Colors.red : Colors.black87,
          fontSize: 14,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
    );
  }

  Future<void> _confirmarLogout(BuildContext context) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirmar Saída'),
          ],
        ),
        content: const Text('Tem certeza que deseja sair da sua conta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      // TODO: Reactivar log de logout quando servico_logs estiver migrado
      // final usuario = SessaoService.instance.usuarioAtual;
      // if (usuario != null) {
      //   await ServicoLogs.instance.registrarLogout(
      //     usuario.idUsuario,
      //     '${usuario.nome} ${usuario.apelido}',
      //   );
      // }

      // TODO: Reactivar quando pedido_contador_service estiver migrado
      // _contadorService.resetar();

      SessaoService.instance.encerrar();
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  // String _getPerfilName(int idPerfil) {
  //   switch (idPerfil) {
  //     case 1:
  //       return 'Administrador';
  //     case 2:
  //       return 'Gerente';
  //     case 3:
  //       return 'Funcionário';
  //     case 4:
  //       return 'Cliente';
  //     default:
  //       return 'Usuário';
  //   }
  // }
}