import 'package:flutter/foundation.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

class DespesaProvider extends ChangeNotifier {
  final DespesaRepository _repository;

  DespesaProvider({
    DespesaRepository? repository,
  }) : _repository = repository ?? DespesaRepository();

  List<DespesaModel> _despesas = [];
  List<TipoDespesaModel> _tiposDespesa = [];
int? _idTipoDespesaFiltro;
  DespesaModel? _despesaSelecionada;
  List<TipoDespesaModel> get tiposDespesa => _tiposDespesa;

  DespesaModel? _ultimaDespesaSalva;

DespesaModel? get ultimaDespesaSalva => _ultimaDespesaSalva;

int? get idTipoDespesaFiltro => _idTipoDespesaFiltro;

bool get temFiltroTipoDespesa => _idTipoDespesaFiltro != null;

  bool _carregando = false;
  bool _salvando = false;
  String? _erro;

  List<DespesaModel> get despesas => _despesas;
  DespesaModel? get despesaSelecionada => _despesaSelecionada;

  bool get carregando => _carregando;
  bool get salvando => _salvando;
  String? get erro => _erro;

  bool get temErro => _erro != null && _erro!.isNotEmpty;
  bool get temDespesas => _despesas.isNotEmpty;

  double get totalDespesas {
    return _despesas.fold<double>(
      0,
      (total, despesa) => total + despesa.valorGasto,
    );
  }

  Future<void> carregarTiposDespesa() async {
  try {
    _tiposDespesa = await _repository.listarTiposDespesa();
    notifyListeners();
  } catch (e) {
    _erro = e.toString();
    notifyListeners();
  }
}

void definirFiltroTipoDespesa(int? idTipoDespesa) {
  _idTipoDespesaFiltro = idTipoDespesa;
  notifyListeners();
}

Future<void> carregarPorPeriodoComFiltro({
  required DateTime inicio,
  required DateTime fim,
}) async {
  _setCarregando(true);
  _limparErro();

  try {
    if (_idTipoDespesaFiltro == null) {
      _despesas = await _repository.listarPorPeriodo(
        inicio: inicio,
        fim: fim,
      );
    } else {
      _despesas = await _repository.listarPorPeriodoETipo(
        inicio: inicio,
        fim: fim,
        idTipoDespesa: _idTipoDespesaFiltro!,
      );
    }
  } catch (e) {
    _erro = e.toString();
  } finally {
    _setCarregando(false);
  }
}



  Future<void> carregarDespesas() async {
    _setCarregando(true);
    _limparErro();

    try {
      _despesas = await _repository.listar();
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setCarregando(false);
    }
  }

  Future<void> buscarPorId(int id) async {
    _setCarregando(true);
    _limparErro();

    try {
      _despesaSelecionada = await _repository.buscarPorId(id);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setCarregando(false);
    }
  }

  Future<void> carregarPorFornecedor(int idFornecedor) async {
    _setCarregando(true);
    _limparErro();

    try {
      _despesas = await _repository.listarPorFornecedor(idFornecedor);
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setCarregando(false);
    }
  }

  Future<void> carregarPorPeriodo({
    required DateTime inicio,
    required DateTime fim,
  }) async {
    _setCarregando(true);
    _limparErro();

    try {
      _despesas = await _repository.listarPorPeriodo(
        inicio: inicio,
        fim: fim,
      );
    } catch (e) {
      _erro = e.toString();
    } finally {
      _setCarregando(false);
    }
  }

Future<bool> criarDespesa(DespesaModel despesa) async {
  _setSalvando(true);
  _limparErro();

  try {
    final criada = await _repository.criar(despesa);

_ultimaDespesaSalva = criada;

inserirOuAtualizarNaLista(criada);

return true;
  } catch (e) {
    _erro = e.toString();
    notifyListeners();
    return false;
  } finally {
    _setSalvando(false);
  }
}

  Future<bool> editarDespesa({
    required int id,
    required DespesaModel despesa,
  }) async {
    _setSalvando(true);
    _limparErro();

    try {
      final atualizada = await _repository.editar(
        id: id,
        despesa: despesa,
      );
_ultimaDespesaSalva = atualizada;

if (_despesaSelecionada?.idDespesa == id) {
  _despesaSelecionada = atualizada;
}

inserirOuAtualizarNaLista(atualizada);

return true;
    } catch (e) {
      _erro = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setSalvando(false);
    }
  }

  Future<bool> excluirDespesa(int id) async {
    _setSalvando(true);
    _limparErro();

    try {
      await _repository.excluir(id);

      _despesas = _despesas
          .where((despesa) => despesa.idDespesa != id)
          .toList();

      if (_despesaSelecionada?.idDespesa == id) {
        _despesaSelecionada = null;
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

void inserirOuAtualizarNaLista(DespesaModel despesa) {
  if (_idTipoDespesaFiltro != null &&
      despesa.idTipoDespesa != _idTipoDespesaFiltro) {
    return;
  }

  _despesas = [
    despesa,
    ..._despesas.where((d) => d.idDespesa != despesa.idDespesa),
  ];

  _despesas.sort((a, b) {
    final dataA = a.dataDespesa ?? DateTime.fromMillisecondsSinceEpoch(0);
    final dataB = b.dataDespesa ?? DateTime.fromMillisecondsSinceEpoch(0);
    return dataB.compareTo(dataA);
  });

  notifyListeners();
}

  void selecionarDespesa(DespesaModel? despesa) {
    _despesaSelecionada = despesa;
    notifyListeners();
  }

  void limparSelecionada() {
    _despesaSelecionada = null;
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