package com.stechengenharia.pdv_backend.sync.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.stechengenharia.pdv_backend.categoria.dto.CategoriaRequestDTO;
import com.stechengenharia.pdv_backend.categoria.service.CategoriaService;
import com.stechengenharia.pdv_backend.cliente.dto.ClienteRequestDTO;
import com.stechengenharia.pdv_backend.cliente.service.ClienteService;
import com.stechengenharia.pdv_backend.marca.dto.MarcaRequestDTO;
import com.stechengenharia.pdv_backend.marca.service.MarcaService;
import com.stechengenharia.pdv_backend.pedido.dto.CancelamentoPedidoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.EditarItemRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.FinalizarPedidoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.ItemPedidoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.ItemServicoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.PedidoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.service.PedidoService;
import com.stechengenharia.pdv_backend.produto.dto.ProdutoRequestDTO;
import com.stechengenharia.pdv_backend.produto.service.ProdutoService;
import com.stechengenharia.pdv_backend.servico.dto.ServicoRequestDTO;
import com.stechengenharia.pdv_backend.servico.service.ServicoService;
import com.stechengenharia.pdv_backend.cotacao.dto.CotacaoRequestDTO;
import com.stechengenharia.pdv_backend.cotacao.service.CotacaoService;
import com.stechengenharia.pdv_backend.sync.dto.SyncOperacaoDTO;
import com.stechengenharia.pdv_backend.sync.dto.SyncRequestDTO;
import com.stechengenharia.pdv_backend.sync.dto.SyncResponseDTO;
import com.stechengenharia.pdv_backend.sync.dto.SyncResultadoDTO;
import com.stechengenharia.pdv_backend.pedido.dto.DeclararCreditoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.CriarParcelasRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.RegistarPagamentoCreditoRequestDTO;
import com.stechengenharia.pdv_backend.fornecedor.dto.FornecedorRequestDTO;
import com.stechengenharia.pdv_backend.fornecedor.service.FornecedorService;
import com.stechengenharia.pdv_backend.despesa.dto.DespesaRequestDTO;
import com.stechengenharia.pdv_backend.despesa.service.DespesaService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class SyncService {

    private final ClienteService   clienteService;
    private final MarcaService     marcaService;
    private final CategoriaService categoriaService;
    private final ServicoService   servicoService;
    private final ProdutoService   produtoService;
    private final PedidoService    pedidoService;
private final CotacaoService   cotacaoService;
private final FornecedorService fornecedorService;
private final DespesaService despesaService;
private final ObjectMapper     objectMapper;

    // ────────────────────────────────────────────────────────────────────────

    public SyncResponseDTO processar(SyncRequestDTO request) {
        List<SyncOperacaoDTO>  operacoes  = request.getOperacoes();
        List<SyncResultadoDTO> resultados = new ArrayList<>();

        for (SyncOperacaoDTO op : operacoes) {
            SyncResultadoDTO resultado = processarOperacao(op);
            resultados.add(resultado);
        }

        long sucesso = resultados.stream().filter(SyncResultadoDTO::isSucesso).count();

        return SyncResponseDTO.builder()
                .totalRecebidas(operacoes.size())
                .totalSucesso((int) sucesso)
                .totalErro((int) (operacoes.size() - sucesso))
                .resultados(resultados)
                .build();
    }

    // ────────────────────────────────────────────────────────────────────────
    // Despachante central — cada operação é isolada (falha não cancela as outras)
    // ────────────────────────────────────────────────────────────────────────

    private SyncResultadoDTO processarOperacao(SyncOperacaoDTO op) {
        try {
            return switch (op.getEntidade().toLowerCase()) {
                case "cliente"   -> processarCliente(op);
                 case "fornecedor" -> processarFornecedor(op);
                case "marca"     -> processarMarca(op);
                case "categoria" -> processarCategoria(op);
                case "servico"   -> processarServico(op);
                case "produto"   -> processarProduto(op);
                case "pedido"    -> processarPedido(op);
                case "cotacao"   -> processarCotacao(op);
                case "despesa" -> processarDespesa(op);
                default          -> erroIndividual(op,
                        "Entidade não suportada: " + op.getEntidade());
            };
        } catch (Exception e) {
            log.warn("[Sync] Falha em {}/{} localId={}: {}",
                    op.getEntidade(), op.getOperacao(), op.getLocalId(), e.getMessage());
            return erroIndividual(op, e.getMessage());
        }
    }

    // ══════════════════════════════════════════════════════════════════════
    // CLIENTE
    // ══════════════════════════════════════════════════════════════════════

    private SyncResultadoDTO processarCliente(SyncOperacaoDTO op) {
        ClienteRequestDTO dto = converter(op.getPayload(), ClienteRequestDTO.class);

        return switch (op.getOperacao().toUpperCase()) {
            case "CREATE" -> {
                var response = clienteService.criar(dto);
                yield sucesso(op, response.id());
            }
            case "UPDATE" -> {
                clienteService.editar(op.getId(), dto);
                yield sucesso(op, op.getId());
            }
            case "DELETE" -> {
                clienteService.excluir(op.getId());
                yield sucesso(op, op.getId());
            }
            default -> erroIndividual(op, "Operação não suportada: " + op.getOperacao());
        };
    }

    // ══════════════════════════════════════════════════════════════════════
    // MARCA
    // ══════════════════════════════════════════════════════════════════════

    private SyncResultadoDTO processarMarca(SyncOperacaoDTO op) {
        MarcaRequestDTO dto = converter(op.getPayload(), MarcaRequestDTO.class);

        return switch (op.getOperacao().toUpperCase()) {
            case "CREATE" -> {
                var response = marcaService.criar(dto);
                yield sucesso(op, (long) response.getIdMarca());
            }
            case "UPDATE" -> {
                marcaService.atualizar(op.getId().intValue(), dto);
                yield sucesso(op, op.getId());
            }
            case "DELETE" -> {
                marcaService.deletar(op.getId().intValue());
                yield sucesso(op, op.getId());
            }
            default -> erroIndividual(op, "Operação não suportada: " + op.getOperacao());
        };
    }

    // ══════════════════════════════════════════════════════════════════════
    // CATEGORIA
    // ══════════════════════════════════════════════════════════════════════

    private SyncResultadoDTO processarCategoria(SyncOperacaoDTO op) {
        CategoriaRequestDTO dto = converter(op.getPayload(), CategoriaRequestDTO.class);

        return switch (op.getOperacao().toUpperCase()) {
            case "CREATE" -> {
                var response = categoriaService.criar(dto);
                yield sucesso(op, (long) response.getIdCategoria());
            }
            case "UPDATE" -> {
                categoriaService.atualizar(op.getId().intValue(), dto);
                yield sucesso(op, op.getId());
            }
            case "DELETE" -> {
                categoriaService.deletar(op.getId().intValue());
                yield sucesso(op, op.getId());
            }
            default -> erroIndividual(op, "Operação não suportada: " + op.getOperacao());
        };
    }

    // ══════════════════════════════════════════════════════════════════════
    // SERVIÇO
    // ══════════════════════════════════════════════════════════════════════

    private SyncResultadoDTO processarServico(SyncOperacaoDTO op) {
        ServicoRequestDTO dto = converter(op.getPayload(), ServicoRequestDTO.class);

        return switch (op.getOperacao().toUpperCase()) {
            case "CREATE" -> {
                var response = servicoService.criar(dto);
                yield sucesso(op, (long) response.idServico);
            }
            case "UPDATE" -> {
                servicoService.actualizar(op.getId().intValue(), dto);
                yield sucesso(op, op.getId());
            }
            case "DELETE" -> {
                servicoService.deletar(op.getId().intValue());
                yield sucesso(op, op.getId());
            }
            default -> erroIndividual(op, "Operação não suportada: " + op.getOperacao());
        };
    }

    // ══════════════════════════════════════════════════════════════════════
    // PRODUTO
    // ══════════════════════════════════════════════════════════════════════

    private SyncResultadoDTO processarProduto(SyncOperacaoDTO op) {
        ProdutoRequestDTO dto = converter(op.getPayload(), ProdutoRequestDTO.class);

        return switch (op.getOperacao().toUpperCase()) {
            case "CREATE" -> {
                var response = produtoService.criar(dto);
                yield sucesso(op, (long) response.getIdProduto());
            }
            case "UPDATE" -> {
                produtoService.atualizar(op.getId().intValue(), dto);
                yield sucesso(op, op.getId());
            }
            case "DELETE" -> {
                produtoService.deletar(op.getId().intValue());
                yield sucesso(op, op.getId());
            }
            default -> erroIndividual(op, "Operação não suportada: " + op.getOperacao());
        };
    }

    // ══════════════════════════════════════════════════════════════════════
    // PEDIDO
    // ══════════════════════════════════════════════════════════════════════

private SyncResultadoDTO processarPedido(SyncOperacaoDTO op) {
        return switch (op.getOperacao().toUpperCase()) {
            case "CREATE" -> {
                PedidoRequestDTO dto = converter(op.getPayload(), PedidoRequestDTO.class);
                var response = pedidoService.criarPedido(dto);
                yield sucesso(op, (long) response.idPedido);
            }

            case "ADD_ITEM_PRODUTO" -> {
                Integer idPedido = extrairIdPedido(op);
                ItemPedidoRequestDTO dto = converter(op.getPayload(), ItemPedidoRequestDTO.class);
                var response = pedidoService.adicionarItemProduto(idPedido, dto);
                yield sucesso(op, (long) response.idPedido);
            }

            case "ADD_ITEM_SERVICO" -> {
                Integer idPedido = extrairIdPedido(op);
                ItemServicoRequestDTO dto = converter(op.getPayload(), ItemServicoRequestDTO.class);
                var response = pedidoService.adicionarItemServico(idPedido, dto);
                yield sucesso(op, (long) response.idPedido);
            }

            case "EDIT_ITEM_PRODUTO" -> {
                Integer idPedido     = extrairIdPedido(op);
                Integer idItemPedido = extrairInt(op, "idItemPedido");
                EditarItemRequestDTO dto = converter(op.getPayload(), EditarItemRequestDTO.class);
                var response = pedidoService.editarQuantidadeItemProduto(idPedido, idItemPedido, dto);
                yield sucesso(op, (long) response.idPedido);
            }

            case "EDIT_ITEM_SERVICO" -> {
                Integer idPedido      = extrairIdPedido(op);
                Integer idItemServico = extrairInt(op, "idItemServico");
                EditarItemRequestDTO dto = converter(op.getPayload(), EditarItemRequestDTO.class);
                var response = pedidoService.editarQuantidadeItemServico(idPedido, idItemServico, dto);
                yield sucesso(op, (long) response.idPedido);
            }

            case "REMOVE_ITEM_PRODUTO" -> {
                Integer idPedido     = extrairIdPedido(op);
                Integer idItemPedido = extrairInt(op, "idItemPedido");
                var response = pedidoService.eliminarItemProduto(idPedido, idItemPedido);
                yield sucesso(op, (long) response.idPedido);
            }

            case "REMOVE_ITEM_SERVICO" -> {
                Integer idPedido      = extrairIdPedido(op);
                Integer idItemServico = extrairInt(op, "idItemServico");
                var response = pedidoService.eliminarItemServico(idPedido, idItemServico);
                yield sucesso(op, (long) response.idPedido);
            }

            case "FINALIZAR" -> {
                Integer idPedido = extrairIdPedido(op);
                FinalizarPedidoRequestDTO dto = converter(op.getPayload(), FinalizarPedidoRequestDTO.class);
                var response = pedidoService.finalizarPedido(idPedido, dto);
                yield sucesso(op, (long) response.idPedido);
            }

            case "CANCEL" -> {
                Integer idPedido = extrairIdPedido(op);
                CancelamentoPedidoRequestDTO dto = converter(op.getPayload(), CancelamentoPedidoRequestDTO.class);
                pedidoService.cancelarPedido(idPedido, dto);
                yield sucesso(op, (long) idPedido);
            }

            case "DELETE" -> {
                pedidoService.eliminar(op.getId().intValue());
                yield sucesso(op, op.getId());
            }
            
            case "DECLARAR_CREDITO" -> {
    Integer idPedido = extrairIdPedido(op);
    DeclararCreditoRequestDTO dto = converter(op.getPayload(), DeclararCreditoRequestDTO.class);
    var response = pedidoService.declararCredito(idPedido, dto);
    yield sucesso(op, (long) response.idPedido);
}

case "CRIAR_PARCELAS" -> {
    Integer idPedido = extrairIdPedido(op);
    CriarParcelasRequestDTO dto = converter(op.getPayload(), CriarParcelasRequestDTO.class);
    pedidoService.criarParcelas(idPedido, dto);
    yield sucesso(op, (long) idPedido);
}

case "REGISTAR_PAGAMENTO" -> {
    Integer idPedido = extrairIdPedido(op);
    RegistarPagamentoCreditoRequestDTO dto = converter(op.getPayload(), RegistarPagamentoCreditoRequestDTO.class);
    var response = pedidoService.registarPagamento(idPedido, dto);
    yield sucesso(op, response.idPagamentoCredito());
}

            default -> erroIndividual(op,
                    "Operação não suportada para pedido via sync: " + op.getOperacao());
        };
    }

    // ══════════════════════════════════════════════════════════════════════
// COTAÇÃO
// ══════════════════════════════════════════════════════════════════════

private SyncResultadoDTO processarCotacao(SyncOperacaoDTO op) {
    return switch (op.getOperacao().toUpperCase()) {

        case "CREATE" -> {
            CotacaoRequestDTO.Criar dto = converter(op.getPayload(), CotacaoRequestDTO.Criar.class);
            var response = cotacaoService.criarCotacao(dto);
            yield sucesso(op, response.idCotacao());
        }

        case "UPDATE" -> {
            CotacaoRequestDTO.Atualizar dto = converter(op.getPayload(), CotacaoRequestDTO.Atualizar.class);
            var response = cotacaoService.atualizarCotacao(op.getId(), dto);
            yield sucesso(op, response.idCotacao());
        }

        case "DELETE" -> {
            cotacaoService.excluirCotacao(op.getId());
            yield sucesso(op, op.getId());
        }

        case "ADD_ITEM_PRODUTO" -> {
            Long idCotacao = extrairLong(op, "idCotacao");
            CotacaoRequestDTO.AdicionarProduto dto = converter(op.getPayload(), CotacaoRequestDTO.AdicionarProduto.class);
            var response = cotacaoService.adicionarProduto(idCotacao, dto);
            yield sucesso(op, response.idCotacao());
        }

        case "ADD_ITEM_SERVICO" -> {
            Long idCotacao = extrairLong(op, "idCotacao");
            CotacaoRequestDTO.AdicionarServico dto = converter(op.getPayload(), CotacaoRequestDTO.AdicionarServico.class);
            var response = cotacaoService.adicionarServico(idCotacao, dto);
            yield sucesso(op, response.idCotacao());
        }

        case "EDIT_ITEM_PRODUTO" -> {
            Long idCotacao = extrairLong(op, "idCotacao");
            Long idItem    = extrairLong(op, "idItem");
            CotacaoRequestDTO.AtualizarItem dto = converter(op.getPayload(), CotacaoRequestDTO.AtualizarItem.class);
            var response = cotacaoService.atualizarItemProduto(idCotacao, idItem, dto);
            yield sucesso(op, response.idCotacao());
        }

        case "EDIT_ITEM_SERVICO" -> {
            Long idCotacao = extrairLong(op, "idCotacao");
            Long idItem    = extrairLong(op, "idItem");
            CotacaoRequestDTO.AtualizarItem dto = converter(op.getPayload(), CotacaoRequestDTO.AtualizarItem.class);
            var response = cotacaoService.atualizarItemServico(idCotacao, idItem, dto);
            yield sucesso(op, response.idCotacao());
        }

        case "REMOVE_ITEM_PRODUTO" -> {
            Long idCotacao = extrairLong(op, "idCotacao");
            Long idItem    = extrairLong(op, "idItem");
            var response = cotacaoService.removerItemProduto(idCotacao, idItem);
            yield sucesso(op, response.idCotacao());
        }

        case "REMOVE_ITEM_SERVICO" -> {
            Long idCotacao = extrairLong(op, "idCotacao");
            Long idItem    = extrairLong(op, "idItem");
            var response = cotacaoService.removerItemServico(idCotacao, idItem);
            yield sucesso(op, response.idCotacao());
        }

        case "CONVERTER" -> {
            Long idCotacao = extrairLong(op, "idCotacao");
            CotacaoRequestDTO.ConverterEmPedido dto = converter(op.getPayload(), CotacaoRequestDTO.ConverterEmPedido.class);
            var response = cotacaoService.converterEmPedido(idCotacao, dto);
            yield sucesso(op, (long) response.idPedido);
        }

        default -> erroIndividual(op,
                "Operação não suportada para cotacao via sync: " + op.getOperacao());
    };
}

// ══════════════════════════════════════════════════════════════════════
// FORNECEDOR
// ══════════════════════════════════════════════════════════════════════

private SyncResultadoDTO processarFornecedor(SyncOperacaoDTO op) {
    FornecedorRequestDTO dto = converter(op.getPayload(), FornecedorRequestDTO.class);

    return switch (op.getOperacao().toUpperCase()) {
        case "CREATE" -> {
            var response = fornecedorService.criar(dto);
            yield sucesso(op, response.id());
        }

        case "UPDATE" -> {
            fornecedorService.editar(op.getId(), dto);
            yield sucesso(op, op.getId());
        }

        case "DELETE" -> {
            fornecedorService.excluir(op.getId());
            yield sucesso(op, op.getId());
        }

        default -> erroIndividual(op,
                "Operação não suportada para fornecedor via sync: " + op.getOperacao());
    };
}

// ══════════════════════════════════════════════════════════════════════
// DESPESA
// ══════════════════════════════════════════════════════════════════════

private SyncResultadoDTO processarDespesa(SyncOperacaoDTO op) {
    DespesaRequestDTO dto =
            converter(op.getPayload(), DespesaRequestDTO.class);

    return switch (op.getOperacao().toUpperCase()) {

        case "CREATE" -> {
            var response = despesaService.criar(dto);
            yield sucesso(op, response.idDespesa());
        }

        case "UPDATE" -> {
            var response = despesaService.editar(op.getId(), dto);
            yield sucesso(op, response.idDespesa());
        }

        case "DELETE" -> {
            despesaService.excluir(op.getId());
            yield sucesso(op, op.getId());
        }

        default -> erroIndividual(
                op,
                "Operação não suportada para despesa via sync: "
                        + op.getOperacao()
        );
    };
}



    // ── Helpers para extrair idPedido / outros ids inteiros do payload ──────

    private Integer extrairIdPedido(SyncOperacaoDTO op) {
        Object valor = op.getPayload().get("idPedido");
        if (valor == null) {
            throw new IllegalArgumentException(
                    "idPedido ausente no payload de " + op.getEntidade() + "/" + op.getOperacao());
        }
        return ((Number) valor).intValue();
    }

    private Integer extrairInt(SyncOperacaoDTO op, String campo) {
        Object valor = op.getPayload().get(campo);
        if (valor == null) {
            throw new IllegalArgumentException(
                    campo + " ausente no payload de " + op.getEntidade() + "/" + op.getOperacao());
        }
        return ((Number) valor).intValue();
    }

    // adicionar após extrairInt
private Long extrairLong(SyncOperacaoDTO op, String campo) {
    Object valor = op.getPayload().get(campo);
    if (valor == null) {
        throw new IllegalArgumentException(
                campo + " ausente no payload de " + op.getEntidade() + "/" + op.getOperacao());
    }
    return ((Number) valor).longValue();
}
    // ══════════════════════════════════════════════════════════════════════
    // UTILITÁRIOS
    // ══════════════════════════════════════════════════════════════════════

    private <T> T converter(Map<String, Object> payload, Class<T> tipo) {
        return objectMapper.convertValue(payload, tipo);
    }

    private SyncResultadoDTO sucesso(SyncOperacaoDTO op, Long idReal) {
        return SyncResultadoDTO.builder()
                .localId(op.getLocalId())
                .entidade(op.getEntidade())
                .operacao(op.getOperacao())
                .sucesso(true)
                .idReal(idReal != null ? idReal.intValue() : null)
                .build();
    }

    private SyncResultadoDTO erroIndividual(SyncOperacaoDTO op, String mensagem) {
        return SyncResultadoDTO.builder()
                .localId(op.getLocalId())
                .entidade(op.getEntidade())
                .operacao(op.getOperacao())
                .sucesso(false)
                .erro(mensagem)
                .build();
    }
}