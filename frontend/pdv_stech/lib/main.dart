// ── PATCH para main.dart ──────────────────────────────────────────
//
// Substitui o bloco de imports e o método main() + MyApp completo.
// Destino: lib/main.dart
//
// Alterações:
//   1. Adicionados imports de LocalDatabase, ConnectivityService,
//      ClienteRepository, ClienteDao, SyncQueueDao
//   2. main() inicializa LocalDatabase e ConnectivityService antes do runApp
//   3. MyApp constrói ClienteRepository e passa-o aos providers
// ─────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:api_compartilhado/api_compartilhado.dart';




import 'screens/usuarios_list_screen.dart';
import 'screens/criar_usuario_screen.dart';
import 'screens/detalhes_usuario_screen.dart';
import 'screens/marcas_list_screen.dart';
import 'screens/marca_form_screen.dart';
import 'screens/categorias_list_screen.dart';
import 'screens/categoria_form_screen.dart';
import 'screens/servico_form_screen.dart';
import 'screens/servico_list_screen.dart';
import 'screens/produto_form_screen.dart';
import 'screens/produto_list_screen.dart';
import 'screens/tela_login.dart';
import 'screens/primeira_troca_senha.dart';
import 'screens/catalogo_screen.dart';
import 'screens/configuracoes_impressora_screen.dart';
import 'screens/pedidos_finalizados_screen.dart';
import 'screens/alterar_senha.dart';
import 'screens/editar_usuario.dart';
import 'screens/dashboard.dart';
import 'screens/splash_screen.dart';
import 'screens/cliente_list_screen.dart';
import 'screens/cliente_form_screen.dart';
import 'screens/documentos_list_screen.dart';
import 'screens/documentos_form_screen.dart';
import 'screens/extractos_list_screen.dart';
import 'screens/extractos_form_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiConfig.baseUrlAsync;
  ApiConfig.printConfig();

  // ── Infraestrutura offline-first (ordem importante) ───────────────
  await LocalDatabase.instance.init();
  await ConnectivityService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

 @override
Widget build(BuildContext context) {
  final connectivity = ConnectivityService.instance;

  // ── Serviços HTTP ─────────────────────────────────────────────────
  final clienteService = ClienteService(
    baseUrl:    ApiConfig.baseUrl,
    httpClient: http.Client(),
  );
final marcaService     = MarcaService();
  final categoriaService = CategoriaService();
  final produtoService   = ProdutoService.instance;
  final servicoService   = ServicoService.instance;
  final pedidoService    = PedidoService();
  final docFiscalService = DocumentoFiscalService();

  // ── Repositórios ──────────────────────────────────────────────────
  final clienteRepository = ClienteRepository(
    service:      clienteService,
    dao:          ClienteDao(),
    syncQueueDao: SyncQueueDao(),
    connectivity: connectivity,
  );

  final marcaRepository = MarcaRepository(
    service:      marcaService,
    dao:          MarcaDao(),
    syncQueueDao: SyncQueueDao(),
    connectivity: connectivity,
  );

  final categoriaRepository = CategoriaRepository(
    service:      categoriaService,
    dao:          CategoriaDao(),
    syncQueueDao: SyncQueueDao(),
    connectivity: connectivity,
  );

  final produtoRepository = ProdutoRepository(
    service:      produtoService,
    dao:          ProdutoDao(),
    syncQueueDao: SyncQueueDao(),
    connectivity: connectivity,
  );

  final servicoRepository = ServicoRepository(
    service:      servicoService,
    dao:          ServicoDao(),
    syncQueueDao: SyncQueueDao(),
    connectivity: connectivity,
  );

  final pedidoRepository = PedidoRepository(
    service:      pedidoService,
    dao:          PedidoDao(),
    syncQueueDao: SyncQueueDao(),
    connectivity: connectivity,
  );

  final docFiscalRepository = DocumentoFiscalRepository(
    service:      docFiscalService,
    dao:          DocumentoFiscalDao(),
    syncQueueDao: SyncQueueDao(),
    connectivity: connectivity,
  );

  return MultiProvider(
    providers: [
      // ── Utilizador ────────────────────────────────────────────────
      ChangeNotifierProvider(create: (_) => UsuarioProvider()),

      // ── Cliente ───────────────────────────────────────────────────
      ChangeNotifierProvider(
        create: (_) => ClienteListaProvider(
          repository:   clienteRepository,
          connectivity: connectivity,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => ClienteFormProvider(repository: clienteRepository),
      ),
      ChangeNotifierProvider(
        create: (_) => ClienteExclusaoProvider(repository: clienteRepository),
      ),

      // ── Marca ─────────────────────────────────────────────────────
      ChangeNotifierProvider(
        create: (_) => MarcaProvider(repository: marcaRepository),
      ),

      // ── Categoria ─────────────────────────────────────────────────
      ChangeNotifierProvider(
        create: (_) => CategoriaProvider(repository: categoriaRepository),
      ),

      // ── Produto ───────────────────────────────────────────────────
      ChangeNotifierProvider(
        create: (_) => ProdutoProvider(),
      ),

      // ── Serviço ───────────────────────────────────────────────────
      ChangeNotifierProvider(
        create: (_) => ServicoProvider(repository: servicoRepository),
      ),

      // ── Pedido ────────────────────────────────────────────────────
      ChangeNotifierProvider(
        create: (_) => PedidoProvider(repository: pedidoRepository),
      ),

      // ── Documento Fiscal ──────────────────────────────────────────
      ChangeNotifierProvider(
        create: (_) => DocumentoFiscalProvider(repository: docFiscalRepository),
      ),
      ],
      child: MaterialApp(
        title: 'Gestor STech',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B2A6B),
            primary:   const Color(0xFF1B2A6B),
          ),
          useMaterial3: true,
        ),

        initialRoute: '/splash',

        routes: {
          '/'                         : (_) => const LoginScreen(),
          '/primeira_troca_senha'     : (_) => const PrimeiraTrocaSenhaScreen(),
          '/gerenciar_usuarios'       : (_) => const UsuariosListScreen(),
          '/usuarios/criar'           : (_) => const CriarUsuarioScreen(),
          '/gerenciar_marcas'         : (_) => const MarcasListScreen(),
          '/gerenciar_categorias'     : (_) => const CategoriasListScreen(),
          '/cadastrar_marcas'         : (_) => const MarcaFormScreen(),
          '/cadastrar_categorias'     : (_) => const CategoriaFormScreen(),
          '/cadastrar_servicos'       : (_) => const ServicoFormScreen(),
          '/gerenciar_servicos'       : (_) => const ServicoListScreen(),
          '/cadastrar_produtos'       : (_) => const ProdutoFormScreen(),
          '/gerenciar_produtos'       : (_) => const ProdutoListScreen(),
          '/catalogo'                 : (_) => const CatalogoScreen(),
          '/configuracoes_impressora' : (_) => const ConfiguracoesImpressoraScreen(),
          '/pedidos_finalizados'      : (_) => const PedidosFinalizadosScreen(),
          '/alterar_senha'            : (_) => const AlterarSenhaScreen(),
          '/editar_usuario'           : (_) => const EditarUsuarioScreen(),
          '/dashboard'                : (_) => const DashboardScreen(),
          '/splash'                   : (_) => const SplashScreen(),
          '/gerenciar_clientes'       : (_) => const ClienteListScreen(),
          '/gerenciar_documentos'     : (_) => const DocumentosListScreen(),
          '/cadastrar_documentos'     : (_) => const DocumentosFormScreen(),
          '/gerenciar_extractos'      : (_) => const ExtratosListScreen(),
          '/cadastrar_extractos'      : (_) => const ExtratosFormScreen(),
        },

        onGenerateRoute: (settings) {
          if (settings.name == '/usuarios/detalhes') {
            return MaterialPageRoute(
              builder:  (_) => const DetalhesUsuarioScreen(),
              settings: settings,
            );
          }
          if (settings.name == '/clientes/empresa/form') {
            final cliente = settings.arguments as ClienteModel?;
            return MaterialPageRoute(
              builder:  (_) => ClienteFormScreen(cliente: cliente),
              settings: settings,
            );
          }
          return null;
        },

        onUnknownRoute: (settings) => MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF1B2A6B),
              foregroundColor: Colors.white,
              title: const Text('Página não encontrada'),
            ),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off_rounded,
                      size: 64, color: Color(0xFF6B7280)),
                  const SizedBox(height: 12),
                  Text(
                    'Rota "${settings.name}" não encontrada.',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}