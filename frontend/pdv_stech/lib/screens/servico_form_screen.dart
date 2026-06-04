// lib/screens/servico_form_screen.dart

import 'package:flutter/material.dart';
import 'package:api_compartilhado/api_compartilhado.dart';

class ServicoFormScreen extends StatefulWidget {
  final ServicoModel? servico;

  const ServicoFormScreen({Key? key, this.servico}) : super(key: key);

  @override
  State<ServicoFormScreen> createState() => _ServicoFormScreenState();
}

class _ServicoFormScreenState extends State<ServicoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServicoService _servicoService = ServicoService.instance;

  late TextEditingController _nomeController;
  late TextEditingController _descricaoController;
  late TextEditingController _precoController;
  late TextEditingController _unidadeController;

  bool _isLoading = false;
  bool _houveAlteracoes = false;
  bool get _isEditMode => widget.servico != null;

  @override
  void initState() {
    super.initState();
    
    _nomeController = TextEditingController(
      text: widget.servico?.nomeServico ?? '',
    );
    _descricaoController = TextEditingController(
      text: widget.servico?.descricao ?? '',
    );
    _precoController = TextEditingController(
      text: widget.servico?.precoUnitario.toStringAsFixed(2) ?? '',
    );
    _unidadeController = TextEditingController(
      text: widget.servico?.unidade ?? 'unidade', // Valor padrão de exemplo
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    _precoController.dispose();
    _unidadeController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Formata a string do preço: substitui vírgula por ponto para o parse
      final precoString = _precoController.text.trim().replaceAll(',', '.');
      final precoDouble = double.parse(precoString);

      final dto = ServicoRequestModel(
        nomeServico: _nomeController.text.trim(),
        descricao: _descricaoController.text.trim().isEmpty 
            ? null 
            : _descricaoController.text.trim(),
        precoUnitario: precoDouble,
        unidade: _unidadeController.text.trim(),
      );

      if (_isEditMode) {
        await _servicoService.actualizar(widget.servico!.idServico, dto);
      } else {
        await _servicoService.criar(dto);
      }

      _houveAlteracoes = true;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Serviço atualizado com sucesso'
                  : 'Serviço criado com sucesso',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Volta para a lista retornando true, forçando o refresh na tela anterior
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nota: Em versões mais recentes do Flutter, o WillPopScope foi substituído
    // pelo PopScope, mas mantive o padrão exato do seu arquivo de referência.
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _houveAlteracoes);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? 'Editar Serviço' : 'Novo Serviço'),
          backgroundColor: const Color(0xFF1B2A6B),
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _houveAlteracoes),
          ),
        ),
        backgroundColor: const Color(0xFFF4F5F7),
        body: _buildFormulario(),
      ),
    );
  }

  Widget _buildFormulario() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.miscellaneous_services,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Informações do Serviço',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  
                  // NOME DO SERVIÇO
                  TextFormField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Serviço *',
                      hintText: 'Ex: Impressão A4, Formatação...',
                      prefixIcon: Icon(Icons.title),
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor, informe o nome do serviço';
                      }
                      if (value.trim().length < 2) {
                        return 'O nome deve ter pelo menos 2 caracteres';
                      }
                      return null;
                    },
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 16),

                  // PREÇO E UNIDADE LADO A LADO
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _precoController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Preço (€) *',
                            hintText: '0.00',
                            prefixIcon: Icon(Icons.euro),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Informe o preço';
                            }
                            final validDouble = double.tryParse(value.replaceAll(',', '.'));
                            if (validDouble == null || validDouble < 0) {
                              return 'Preço inválido';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _unidadeController,
                          decoration: const InputDecoration(
                            labelText: 'Unidade *',
                            hintText: 'página, hora...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Obrigatório';
                            }
                            return null;
                          },
                          enabled: !_isLoading,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // DESCRIÇÃO
                  TextFormField(
                    controller: _descricaoController,
                    decoration: const InputDecoration(
                      labelText: 'Descrição (Opcional)',
                      hintText: 'Detalhes adicionais sobre o serviço...',
                      prefixIcon: Icon(Icons.description),
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isLoading,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // BOTÕES DE AÇÃO
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pop(context, _houveAlteracoes),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancelar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _salvar,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isEditMode ? 'Atualizar' : 'Salvar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC8102E), // kVermelho
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}