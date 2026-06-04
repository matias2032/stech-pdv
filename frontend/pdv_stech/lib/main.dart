// main.dart
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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ── Service partilhado pelos três providers de cliente ────────────────────
    final clienteService = ClienteService(
      baseUrl: ApiConfig.baseUrl,
      httpClient: http.Client(),
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UsuarioProvider()),

        // ── Cliente ───────────────────────────────────────────────────────────
        ChangeNotifierProvider(
          create: (_) => ClienteListaProvider(service: clienteService),
        ),
        ChangeNotifierProvider(
          create: (_) => ClienteFormProvider(service: clienteService),
        ),
        ChangeNotifierProvider(
          create: (_) => ClienteExclusaoProvider(service: clienteService),
        ),

        ChangeNotifierProvider(create: (_) => PedidoProvider()),
        
  ChangeNotifierProvider(
    create: (_) => DocumentoFiscalProvider(),
  ),
 
      ],
      child: MaterialApp(
        title: 'Gestor STech',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B2A6B),
            primary: const Color(0xFF1B2A6B),
          ),
          useMaterial3: true,
        ),

        // ── Rota inicial ──────────────────────────────────────────────────────
        initialRoute: '/splash',

        // ── Tabela de rotas nomeadas ───────────────────────────────────────────
        routes: {
          '/'                          : (_) => const LoginScreen(),
          '/primeira_troca_senha'      : (_) => const PrimeiraTrocaSenhaScreen(),
          '/gerenciar_usuarios'        : (_) => const UsuariosListScreen(),
          '/usuarios/criar'            : (_) => const CriarUsuarioScreen(),
          '/gerenciar_marcas'          : (_) => const MarcasListScreen(),
          '/gerenciar_categorias'      : (_) => const CategoriasListScreen(),
          '/cadastrar_marcas'          : (_) => const MarcaFormScreen(),
          '/cadastrar_categorias'      : (_) => const CategoriaFormScreen(),
          '/cadastrar_servicos'        : (_) => const ServicoFormScreen(),
          '/gerenciar_servicos'        : (_) => const ServicoListScreen(),
          '/cadastrar_produtos'        : (_) => const ProdutoFormScreen(),
          '/gerenciar_produtos'        : (_) => const ProdutoListScreen(),
          '/catalogo'                  : (_) => const CatalogoScreen(),
          '/configuracoes_impressora'  : (_) => const ConfiguracoesImpressoraScreen(),
          '/pedidos_finalizados'       : (_) => const PedidosFinalizadosScreen(),
          '/alterar_senha'             : (_) => const AlterarSenhaScreen(),
          '/editar_usuario'            : (_) => const EditarUsuarioScreen(),
          '/dashboard'                 : (_) => const DashboardScreen(),
          '/splash'                    : (_) => const SplashScreen(),
          '/gerenciar_clientes'        : (_) => const ClienteListScreen(),
          '/gerenciar_documentos'      : (_) => const DocumentosListScreen(),
          '/cadastrar_documentos'        : (_) => const DocumentosFormScreen(),
             '/gerenciar_extractos'      : (_) => const ExtratosListScreen(),
          '/cadastrar_extractos'        : (_) => const ExtratosFormScreen(),
        },

        // ── Rotas com argumentos ───────────────────────────────────────────────
        onGenerateRoute: (settings) {
          // Detalhes de usuário
          if (settings.name == '/usuarios/detalhes') {
            return MaterialPageRoute(
              builder: (_) => const DetalhesUsuarioScreen(),
              settings: settings,
            );
          }

          // Formulário de cliente (criação sem argumento, edição com ClienteModel)
          if (settings.name == '/clientes/empresa/form') {
            final cliente = settings.arguments as ClienteModel?;
            return MaterialPageRoute(
              builder: (_) => ClienteFormScreen(cliente: cliente),
              settings: settings,
            );
          }

          return null;
        },

        // ── Rota de fallback (404 interno) ─────────────────────────────────────
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