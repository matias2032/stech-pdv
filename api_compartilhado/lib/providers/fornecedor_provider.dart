import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart';


class FornecedorProvider extends ChangeNotifier {
  final FornecedorRepository _repository;

  FornecedorProvider({
    FornecedorRepository? repository,
  }) : _repository = repository ?? FornecedorRepository();

  List<FornecedorModel> _fornecedores = [];
  FornecedorModel? _fornecedorSelecionado;

  bool _carregando = false;
  bool _salvando = false;
  String? _erro;

  List<FornecedorModel> get fornecedores => _fornecedores;
  FornecedorModel? get fornecedorSelecionado => _fornecedorSelecionado;

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;

  bool get temErro => _erro != null && _erro!.isNotEmpty;
  bool get temFornecedores => _fornecedores.isNotEmpty;

  // ─────────────────────────────────────────────────────────────
  // LISTAR
  // ─────────────────────────────────────────────────────────────

  Future<void> carregarFornecedores() async {
    _setCarregando(true);
    _limparErro();

    try {
      _fornecedores = await _repository.listar();
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setCarregando(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // PESQUISAR
  // ─────────────────────────────────────────────────────────────

  Future<void> pesquisarFornecedores(String termo) async {
    _setCarregando(true);
    _limparErro();

    try {
      _fornecedores = await _repository.pesquisar(termo);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setCarregando(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BUSCAR POR ID
  // ─────────────────────────────────────────────────────────────

  Future<void> buscarPorId(int id) async {
    _setCarregando(true);
    _limparErro();

    try {
      _fornecedorSelecionado = await _repository.buscarPorId(id);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setCarregando(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CRIAR
  // ─────────────────────────────────────────────────────────────

  Future<bool> criarFornecedor(FornecedorModel fornecedor) async {
    _setSalvando(true);
    _limparErro();

    try {
      final criado = await _repository.criar(fornecedor);

      _fornecedores = [
        criado,
        ..._fornecedores.where((f) => f.id != criado.id),
      ];

      notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setSalvando(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // EDITAR
  // ─────────────────────────────────────────────────────────────

  Future<bool> editarFornecedor({
    required int id,
    required FornecedorModel fornecedor,
  }) async {
    _setSalvando(true);
    _limparErro();

    try {
      final atualizado = await _repository.editar(
        id: id,
        fornecedor: fornecedor,
      );

      _fornecedores = _fornecedores.map((item) {
        if (item.id == id) return atualizado;
        return item;
      }).toList();

      if (_fornecedorSelecionado?.id == id) {
        _fornecedorSelecionado = atualizado;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setSalvando(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // EXCLUIR
  // ─────────────────────────────────────────────────────────────

  Future<bool> excluirFornecedor(int id) async {
    _setSalvando(true);
    _limparErro();

    try {
      await _repository.excluir(id);

      _fornecedores = _fornecedores
          .where((fornecedor) => fornecedor.id != id)
          .toList();

      if (_fornecedorSelecionado?.id == id) {
        _fornecedorSelecionado = null;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setSalvando(false);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // ESTADO LOCAL
  // ─────────────────────────────────────────────────────────────

  void selecionarFornecedor(FornecedorModel? fornecedor) {
    _fornecedorSelecionado = fornecedor;
    notifyListeners();
  }

  void limparSelecionado() {
    _fornecedorSelecionado = null;
    notifyListeners();
  }

  void limparErro() {
    _limparErro();
    notifyListeners();
  }

  void _limparErro() {
    _erro = null;
  }

  void _setCarregando(bool valor) {
    _carregando = valor;
    notifyListeners();
  }

  void _setSalvando(bool valor) {
    _salvando = valor;
    notifyListeners();
  }
}