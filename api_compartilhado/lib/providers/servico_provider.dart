import 'package:flutter/material.dart';
import '../models/servico_model.dart';
import '../services/servico_service.dart';

class ServicoProvider with ChangeNotifier {
  // Instância do serviço
  final ServicoService _service = ServicoService.instance;

  // Estados internos
  List<ServicoModel> _servicos = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters públicos para a UI
  List<ServicoModel> get servicos => _servicos;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE LEITURA (GET)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Carrega todos os serviços (Ativos e Inativos) - Ideal para Admin/Gestão
  Future<void> carregarTodosOsServicos() async {
    _setLoading(true);
    _clearError();

    try {
      _servicos = await _service.listarTodos();
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  /// Carrega apenas os serviços ativos - Ideal para ecrãs de pedidos/clientes
  Future<void> carregarServicosAtivos() async {
    _setLoading(true);
    _clearError();

    try {
      _servicos = await _service.listarAtivos();
    } catch (e) {
      _errorMessage = _parseError(e);
    } finally {
      _setLoading(false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE MUTAÇÃO (POST, PUT, PATCH)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Cria um novo serviço e atualiza a lista local em memória
  Future<bool> criarServico(ServicoRequestModel dto) async {
    _setLoading(true);
    _clearError();

    try {
      final novoServico = await _service.criar(dto);
      _servicos.add(novoServico);
      notifyListeners();
      return true; // Sucesso
    } catch (e) {
      _errorMessage = _parseError(e);
      return false; // Falha
    } finally {
      _setLoading(false);
    }
  }

  /// Atualiza um serviço existente e reflete a mudança na lista local
  Future<bool> actualizarServico(int id, ServicoRequestModel dto) async {
    _setLoading(true);
    _clearError();

    try {
      final servicoAtualizado = await _service.actualizar(id, dto);
      
      // Encontra o index e atualiza o item na lista local
      final index = _servicos.indexWhere((s) => s.idServico == id);
      if (index != -1) {
        _servicos[index] = servicoAtualizado;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Inverte o estado de ativo/inativo sem precisar recarregar toda a API
  Future<bool> toggleEstadoServico(int id) async {
    _clearError();

    try {
      final servicoModificado = await _service.toggleAtivo(id);
      
      final index = _servicos.indexWhere((s) => s.idServico == id);
      if (index != -1) {
        _servicos[index] = servicoModificado;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // AUXILIARES PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  String _parseError(Object error) {
    // Captura o erro HTTP lançado pelo seu assertStatus ou problemas de rede
    return error.toString().replaceAll('Exception: ', '');
  }
}