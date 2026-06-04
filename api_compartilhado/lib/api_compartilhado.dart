library api_compartilhado;

// 1. Configuração da API
export 'api_config.dart';

// 2. Models
export 'models/usuario_model.dart';
export 'models/resultado_autenticacao.dart';
export 'models/api_response.dart';
export 'models/produto_model.dart';
export 'models/produto_request.dart';
export 'models/disponibilidade_produto_model.dart';
export 'models/servico_model.dart';
export 'models/preco_produto_model.dart';
export 'models/estoque_model.dart';
export 'models/movimento_estoque_model.dart';
export 'models/pedido_request.dart';
export 'models/pedido_model.dart';
export 'models/categoria_model.dart';
export 'models/marca_model.dart';
export 'models/cliente_model.dart';
export 'models/documento_fiscal_model.dart'; // ← TipoDocumentoModel + DocumentoFiscalModel (API)
export 'models/extrato_model.dart';

// 3. Services
export 'services/sessao_service.dart';
export 'services/servico_autenticacao.dart';
export 'services/pedido_service.dart';
export 'services/estoque_service.dart';
export 'services/produto_service.dart';
export 'services/impressora_service.dart';
// pdf_service.dart NÃO é exportado aqui — usa DocumentoPdfModel (local)
// e deve ser importado directamente onde for usado:
//   import 'package:api_compartilhado/services/pdf_service.dart';
export 'services/firebase_listener_service.dart';
export 'services/sync_queue_service.dart';
export 'services/connectivity_service.dart';
export 'services/usuario_service.dart';
export 'services/marca_service.dart';
export 'services/categoria_service.dart';
export 'services/servico_service.dart';
export 'services/cliente_service.dart';
export 'services/documento_fiscal_service.dart'; // ← DocumentoFiscalService
export 'services/extrato_service.dart'; 
export 'services/extrato_pdf_service.dart'; 


// 4. Providers
export 'providers/produto_provider.dart';
export 'providers/estoque_provider.dart';
export 'providers/pedido_provider.dart';
export 'providers/servico_provider.dart';
export 'providers/cliente_provider.dart';
export 'providers/usuario_provider.dart' hide UsuarioService;
export 'providers/documento_fiscal_provider.dart'; // ← DocumentoFiscalProvider
export 'core/constants/constantes_fiscais.dart';

// 5. Controllers
export 'controllers/pedido_ativo_controller.dart';