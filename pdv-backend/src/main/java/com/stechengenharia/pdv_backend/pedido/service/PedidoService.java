package com.stechengenharia.pdv_backend.pedido.service;

import com.stechengenharia.pdv_backend.cliente.repository.ClienteRepository;
import com.stechengenharia.pdv_backend.pedido.dto.*;
import com.stechengenharia.pdv_backend.pedido.entity.*;
import com.stechengenharia.pdv_backend.pedido.exception.*;
import com.stechengenharia.pdv_backend.pedido.repository.*;
import com.stechengenharia.pdv_backend.produto.entity.Produto;
import com.stechengenharia.pdv_backend.produto.repository.ProdutoRepository;
import com.stechengenharia.pdv_backend.servico.entity.Servico;
import com.stechengenharia.pdv_backend.servico.service.ServicoService;
import com.stechengenharia.pdv_backend.cliente.repository.*;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class PedidoService {

    // ─── Repositórios ────────────────────────────────────────────────────────
    private final PedidoRepository              pedidoRepository;
    private final ItemPedidoRepository          itemPedidoRepository;
    private final ItemPedidoServicoRepository   itemPedidoServicoRepository;
    private final PedidoCancelamentoRepository  cancelamentoRepository;
    private final ProdutoRepository             produtoRepository;
    private final TipoPagamentoRepository       tipoPagamentoRepository;
    private final ClienteRepository clienteRepository;

    // ─── Serviços cross-module ───────────────────────────────────────────────
    private final ServicoService servicoService;

    // ─── Constantes ──────────────────────────────────────────────────────────
    private static final List<String> STATUS_EDITAVEIS = List.of("aberto");

    // ════════════════════════════════════════════════════════════════════════
    // a) CRIAÇÃO DO PEDIDO
    // ════════════════════════════════════════════════════════════════════════

@Transactional
public PedidoResponseDTO criarPedido(PedidoRequestDTO dto) {
    log.info("Criando pedido para utilizador {}", dto.idUsuario);

    Pedido pedido = Pedido.builder()
            .referencia(gerarReferencia())
            .idUsuario(dto.idUsuario)
            .idTipoPagamento(dto.idTipoPagamento)
            .statusPedido("aberto")
            .total(BigDecimal.ZERO)
            .valorPago(BigDecimal.ZERO)
            .pontoReferencia(dto.pontoReferencia)
            .observacoes(dto.observacoes)
            .dataPedido(LocalDateTime.now())
            .build();

    pedido.setSyncStatus("PENDING_CREATE"); // AuditableEntity já define, mas explícito

    pedido = pedidoRepository.save(pedido);

        if (dto.itensProduto != null) {
            for (ItemPedidoRequestDTO itemDto : dto.itensProduto) {
                adicionarItemProdutoInterno(pedido, itemDto.idProduto, itemDto.quantidade);
            }
        }

        if (dto.itensServico != null) {
            for (ItemServicoRequestDTO itemDto : dto.itensServico) {
                adicionarItemServicoInterno(pedido, itemDto);
            }
        }

        pedido.recalcularTotal();
        pedido = pedidoRepository.save(pedido);

        log.info("Pedido {} criado | Total: {}", pedido.getReferencia(), pedido.getTotal());
        return toResponseDTO(pedido);
    }

    // ════════════════════════════════════════════════════════════════════════
    // b) ADICIONAR ITEM DE PRODUTO
    // ════════════════════════════════════════════════════════════════════════

    @Transactional
    public PedidoResponseDTO adicionarItemProduto(Integer idPedido, ItemPedidoRequestDTO dto) {
        Pedido pedido = buscarPedidoComItens(idPedido);
        validarStatusEditavel(pedido, "adição de item de produto");

        adicionarItemProdutoInterno(pedido, dto.idProduto, dto.quantidade);
        pedido.recalcularTotal();
        pedidoRepository.save(pedido);

        log.info("Produto {} adicionado ao pedido {}", dto.idProduto, idPedido);
        return toResponseDTO(pedido);
    }

    // ════════════════════════════════════════════════════════════════════════
    // c) ADICIONAR ITEM DE SERVIÇO
    // ════════════════════════════════════════════════════════════════════════

    @Transactional
    public PedidoResponseDTO adicionarItemServico(Integer idPedido, ItemServicoRequestDTO dto) {
        Pedido pedido = buscarPedidoComItens(idPedido);
        validarStatusEditavel(pedido, "adição de item de serviço");

        adicionarItemServicoInterno(pedido, dto);
        pedido.recalcularTotal();
        pedidoRepository.save(pedido);

        log.info("Serviço {} adicionado ao pedido {}", dto.idServico, idPedido);
        return toResponseDTO(pedido);
    }

    // ════════════════════════════════════════════════════════════════════════
    // d) EDITAR QUANTIDADE DE ITEM DE PRODUTO
    // ════════════════════════════════════════════════════════════════════════

    @Transactional
    public PedidoResponseDTO editarQuantidadeItemProduto(
            Integer idPedido,
            Integer idItemPedido,
            EditarItemRequestDTO dto) {

        Pedido pedido = buscarPedidoComItens(idPedido);
        validarStatusEditavel(pedido, "edição de item de produto");

        ItemPedido item = itemPedidoRepository
                .findByIdItemPedidoAndPedidoIdPedido(idItemPedido, idPedido)
                .orElseThrow(() -> new ItemNaoPertenceAoPedidoException(idItemPedido, idPedido));

        Produto produto = item.getProduto();
        int quantidadeAnterior = item.getQuantidade();
        int novaQuantidade     = dto.novaQuantidade;
        int diferenca          = novaQuantidade - quantidadeAnterior;

        if (diferenca > 0) {
            garantirEstoqueDisponivel(produto, diferenca);
            ajustarEstoqueSemMovimento(produto, -diferenca);
        } else if (diferenca < 0) {
            ajustarEstoqueSemMovimento(produto, Math.abs(diferenca));
        }

        item.setQuantidade(novaQuantidade);
        itemPedidoRepository.save(item);

        pedido.recalcularTotal();
        pedidoRepository.save(pedido);

        log.info("Item produto {} do pedido {}: {} → {} unidades",
                idItemPedido, idPedido, quantidadeAnterior, novaQuantidade);

        return toResponseDTO(pedido);
    }

    // ════════════════════════════════════════════════════════════════════════
    // e) EDITAR QUANTIDADE DE ITEM DE SERVIÇO
    // ════════════════════════════════════════════════════════════════════════

    @Transactional
    public PedidoResponseDTO editarQuantidadeItemServico(
            Integer idPedido,
            Integer idItemServico,
            EditarItemRequestDTO dto) {

        Pedido pedido = buscarPedidoComItens(idPedido);
        validarStatusEditavel(pedido, "edição de item de serviço");

        ItemPedidoServico item = itemPedidoServicoRepository
                .findByIdItemServicoAndPedido_IdPedido(idItemServico, idPedido)
                .orElseThrow(() -> new ItemNaoPertenceAoPedidoException(idItemServico, idPedido));

        int anterior = item.getQuantidade();
        item.setQuantidade(dto.novaQuantidade);
        itemPedidoServicoRepository.save(item);

        pedido.recalcularTotal();
        pedidoRepository.save(pedido);

        log.info("Item serviço {} do pedido {}: {} → {} unidades",
                idItemServico, idPedido, anterior, dto.novaQuantidade);

        return toResponseDTO(pedido);
    }

    // ════════════════════════════════════════════════════════════════════════
    // f) ELIMINAR ITEM DE PRODUTO
    // ════════════════════════════════════════════════════════════════════════

    @Transactional
    public PedidoResponseDTO eliminarItemProduto(Integer idPedido, Integer idItemPedido) {
        Pedido pedido = buscarPedidoComItens(idPedido);
        validarStatusEditavel(pedido, "eliminação de item de produto");

        ItemPedido item = itemPedidoRepository
                .findByIdItemPedidoAndPedidoIdPedido(idItemPedido, idPedido)
                .orElseThrow(() -> new ItemNaoPertenceAoPedidoException(idItemPedido, idPedido));

        Produto produto = item.getProduto();
        ajustarEstoqueSemMovimento(produto, item.getQuantidade());

        pedido.getItensProduto().remove(item);
        itemPedidoRepository.delete(item);

        pedido.recalcularTotal();
        pedidoRepository.save(pedido);

        log.info("Item produto {} eliminado do pedido {}. Estoque produto {} restaurado em {}",
                idItemPedido, idPedido, produto.getIdProduto(), item.getQuantidade());

        return toResponseDTO(pedido);
    }

    @Transactional
public void eliminar(Integer idPedido) {
    Pedido pedido = pedidoRepository.findById(idPedido)
            .orElseThrow(() -> new PedidoNaoEncontradoException(idPedido));
    pedido.setDeleted(true);
    pedido.setSyncStatus("PENDING_DELETE");
    pedidoRepository.save(pedido);
    log.info("Pedido {} marcado como eliminado", idPedido);
}

    // ════════════════════════════════════════════════════════════════════════
    // g) ELIMINAR ITEM DE SERVIÇO
    // ════════════════════════════════════════════════════════════════════════

    @Transactional
    public PedidoResponseDTO eliminarItemServico(Integer idPedido, Integer idItemServico) {
        Pedido pedido = buscarPedidoComItens(idPedido);
        validarStatusEditavel(pedido, "eliminação de item de serviço");

        ItemPedidoServico item = itemPedidoServicoRepository
                .findByIdItemServicoAndPedido_IdPedido(idItemServico, idPedido)
                .orElseThrow(() -> new ItemNaoPertenceAoPedidoException(idItemServico, idPedido));

        pedido.getItensServico().remove(item);
        itemPedidoServicoRepository.delete(item);

        pedido.recalcularTotal();
        pedidoRepository.save(pedido);

        log.info("Item serviço {} eliminado do pedido {}", idItemServico, idPedido);
        return toResponseDTO(pedido);
    }

    // ════════════════════════════════════════════════════════════════════════
    // h) FINALIZAR PEDIDO
    // ════════════════════════════════════════════════════════════════════════

   @Transactional
public PedidoResponseDTO finalizarPedido(Integer idPedido, FinalizarPedidoRequestDTO dto) {
    Pedido pedido = buscarPedidoComItens(idPedido);

    if ("finalizado".equalsIgnoreCase(pedido.getStatusPedido()) ||
        "cancelado".equalsIgnoreCase(pedido.getStatusPedido())) {
        throw new StatusPedidoInvalidoException(pedido.getStatusPedido(), "finalização");
    }

    pedido.setIdTipoPagamento(dto.idTipoPagamento);

    if (dto.valorPago == null || dto.valorPago.compareTo(BigDecimal.ZERO) < 0) {
        throw new IllegalArgumentException("valorPago é obrigatório e não pode ser negativo");
    }
    pedido.setValorPago(dto.valorPago);

    if (dto.observacoes != null && !dto.observacoes.isBlank()) {
        pedido.setObservacoes(dto.observacoes);
    }

// ── Associar cliente ─────────────────────────────────────────────────
if (dto.idCliente != null) {
    clienteRepository.findById(dto.idCliente)
        .orElseThrow(() -> new RuntimeException("Cliente não encontrado: " + dto.idCliente));
    pedido.setIdCliente(dto.idCliente);
} else {
    // Cliente singular — id_cliente fica NULL; nome/apelido são transitórios
    pedido.setIdCliente(null);                              // ← era 1L
    pedido.setNomeClienteSingular(dto.nomeClienteSingular);
    pedido.setApelidoClienteSingular(dto.apelidoClienteSingular);
}

    pedido.setStatusPedido("finalizado");
    pedido.setDataFinalizacao(LocalDateTime.now());
    pedido.setSyncStatus("PENDING_UPDATE"); // finalização deve chegar à nuvem
pedidoRepository.save(pedido);

    log.info("Pedido {} finalizado | cliente: {} | total: {} | pago: {}",
            pedido.getReferencia(), pedido.getIdCliente(),
            pedido.getTotal(), dto.valorPago);

    return toResponseDTO(pedido);
}

    // ════════════════════════════════════════════════════════════════════════
    // i) CANCELAR PEDIDO
    // ════════════════════════════════════════════════════════════════════════

    @Transactional
public void cancelarPedido(Integer idPedido, CancelamentoPedidoRequestDTO dto) {
    Pedido pedido = buscarPedidoComItens(idPedido);

    if ("cancelado".equalsIgnoreCase(pedido.getStatusPedido())) {
        throw new StatusPedidoInvalidoException(pedido.getStatusPedido(), "cancelamento");
    }

    for (ItemPedido item : pedido.getItensProduto()) {
        Produto produto = item.getProduto();
        ajustarEstoqueSemMovimento(produto, item.getQuantidade());
        log.info("Cancelamento pedido {}: estoque produto {} restaurado em {}",
                idPedido, produto.getIdProduto(), item.getQuantidade());
    }

    pedido.setStatusPedido("cancelado");
    pedido.setDataFinalizacao(LocalDateTime.now());
    pedido.setSyncStatus("PENDING_UPDATE"); // mudança de status deve chegar à nuvem
    pedidoRepository.save(pedido);

    PedidoCancelamento cancelamento = PedidoCancelamento.builder()
            .pedido(pedido)
            .motivo(dto.motivo)
            .idUsuarioCancelou(dto.idUsuarioCancelou)
            .dataCancelamento(LocalDateTime.now())
            .build();

    cancelamentoRepository.save(cancelamento);
    log.info("Pedido {} cancelado por utilizador {}", pedido.getReferencia(), dto.idUsuarioCancelou);
}

    // ════════════════════════════════════════════════════════════════════════
    // CONSULTAS
    // ════════════════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public PedidoResponseDTO buscarPorId(Integer idPedido) {
        return toResponseDTO(buscarPedidoComItens(idPedido));
    }

@Transactional(readOnly = true)
public List<PedidoResponseDTO> listarPorStatus(String status) {
    return pedidoRepository
            .findByStatusPedidoAndDeletedFalseOrderByDataPedidoDesc(status) // era findByStatusPedido
            .stream().map(this::toResponseDTO).collect(Collectors.toList());
}

@Transactional(readOnly = true)
public List<PedidoResponseDTO> listarPorUsuario(Integer idUsuario) {
    return pedidoRepository
            .findByIdUsuarioAndDeletedFalseOrderByDataPedidoDesc(idUsuario) // era findByIdUsuario
            .stream().map(this::toResponseDTO).collect(Collectors.toList());
}

    @Transactional(readOnly = true)
    public List<PedidoResponseDTO> listarPorUsuarioEStatus(Integer idUsuario, String status) {
        return pedidoRepository
                .findByIdUsuarioAndStatusPedidoOrderByDataPedidoDesc(idUsuario, status)
                .stream()
                .map(this::toResponseDTO)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<TipoPagamentoResponseDTO> listarTiposPagamento() {
        return tipoPagamentoRepository.findAll().stream().map(t -> {
            TipoPagamentoResponseDTO dto = new TipoPagamentoResponseDTO();
            dto.idTipoPagamento = t.getIdTipoPagamento();
            dto.tipoPagamento   = t.getTipoPagamento();
            return dto;
        }).collect(Collectors.toList());
    }

    // ════════════════════════════════════════════════════════════════════════
    // MÉTODOS PRIVADOS
    // ════════════════════════════════════════════════════════════════════════

    private void adicionarItemProdutoInterno(Pedido pedido, Integer idProduto, Integer quantidade) {
        Produto produto = produtoRepository.findById(idProduto)
                .orElseThrow(() -> new RuntimeException("Produto não encontrado: " + idProduto));

        garantirEstoqueDisponivel(produto, quantidade);

        BigDecimal precoUnitario = produto.getPrecoPromocional() != null
                ? produto.getPrecoPromocional()
                : produto.getPreco();

        ItemPedido item = ItemPedido.builder()
                .pedido(pedido)
                .produto(produto)
                .quantidade(quantidade)
                .precoUnitario(precoUnitario)
                .build();

        itemPedidoRepository.save(item);
        pedido.getItensProduto().add(item);
        ajustarEstoqueSemMovimento(produto, -quantidade);

        log.info("Item produto '{}' criado | qty: {} | preço: {}",
                produto.getNomeProduto(), quantidade, precoUnitario);
    }

    /**
     * Valida existência e estado activo do serviço via ServicoService.
     * O preço unitário é sempre lido do catálogo — não aceita override do frontend.
     */
// DEPOIS
private void adicionarItemServicoInterno(Pedido pedido, ItemServicoRequestDTO dto) {
    Servico servico = servicoService.validarServicoDisponivel(dto.idServico);

    ItemPedidoServico item = ItemPedidoServico.builder()
            .pedido(pedido)
            .servico(servico)
            .quantidade(dto.quantidade)
            .precoUnitario(servico.getPrecoUnitario())
            .observacoes(dto.observacoes)
            .build();

    itemPedidoServicoRepository.save(item);   // ✅ persiste com preço
    pedido.getItensServico().add(item);

    log.info("Item serviço '{}' criado | qty: {} | preço: {}",
            servico.getNomeServico(), dto.quantidade, servico.getPrecoUnitario());
}

    private void ajustarEstoqueSemMovimento(Produto produto, int delta) {
        int estoqueActual  = produto.getQuantidadeEstoque();
        int novaQuantidade = estoqueActual + delta;

        if (novaQuantidade < 0) {
            throw new EstoqueInsuficienteException(
                    produto.getNomeProduto(), estoqueActual, Math.abs(delta));
        }

        produtoRepository.ajustarEstoque(produto.getIdProduto(), delta);
        produto.setQuantidadeEstoque(novaQuantidade);

        log.debug("Estoque produto {} ajustado: {} → {} (delta: {})",
                produto.getIdProduto(), estoqueActual, novaQuantidade, delta);
    }

    private void garantirEstoqueDisponivel(Produto produto, int quantidadeSolicitada) {
        if (produto.getQuantidadeEstoque() < quantidadeSolicitada) {
            throw new EstoqueInsuficienteException(
                    produto.getNomeProduto(),
                    produto.getQuantidadeEstoque(),
                    quantidadeSolicitada);
        }
    }

    private void validarStatusEditavel(Pedido pedido, String operacao) {
        if (!STATUS_EDITAVEIS.contains(pedido.getStatusPedido())) {
            throw new StatusPedidoInvalidoException(pedido.getStatusPedido(), operacao);
        }
    }

    private Pedido buscarPedidoComItens(Integer idPedido) {
        return pedidoRepository.findByIdComItens(idPedido)
                .orElseThrow(() -> new PedidoNaoEncontradoException(idPedido));
    }

    private String gerarReferencia() {
        return "PED-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    
    // ════════════════════════════════════════════════════════════════════════
    // MAPEAMENTO ENTITY → DTO
    // ════════════════════════════════════════════════════════════════════════

    private PedidoResponseDTO toResponseDTO(Pedido pedido) {
        PedidoResponseDTO dto = new PedidoResponseDTO();
        dto.idPedido        = pedido.getIdPedido();
        dto.referencia      = pedido.getReferencia();
        dto.idUsuario       = pedido.getIdUsuario();
        dto.idTipoPagamento = pedido.getIdTipoPagamento();
        dto.statusPedido    = pedido.getStatusPedido();
        dto.total           = pedido.getTotal();
        dto.valorPago       = pedido.getValorPago();
        dto.troco           = pedido.getTroco();
        dto.pontoReferencia = pedido.getPontoReferencia();
        dto.observacoes     = pedido.getObservacoes();
        dto.dataPedido      = pedido.getDataPedido();
        dto.dataFinalizacao = pedido.getDataFinalizacao();

        dto.itensProduto = pedido.getItensProduto().stream()
                .map(this::toItemPedidoResponseDTO)
                .collect(Collectors.toList());

        dto.itensServico = pedido.getItensServico().stream()
                .map(this::toItemServicoResponseDTO)
                .collect(Collectors.toList());

                dto.nomeClienteSingular    = pedido.getNomeClienteSingular();
dto.apelidoClienteSingular = pedido.getApelidoClienteSingular();
dto.idCliente = pedido.getIdCliente();

        return dto;
    }

 private ItemPedidoResponseDTO toItemPedidoResponseDTO(ItemPedido item) {
    ItemPedidoResponseDTO dto = new ItemPedidoResponseDTO();
    dto.idItemPedido  = item.getIdItemPedido();
    dto.idProduto     = item.getProduto().getIdProduto();
    dto.nomeProduto   = item.getProduto().getNomeProduto();
    dto.quantidade    = item.getQuantidade();
    dto.precoUnitario = item.getPrecoUnitario();
    // ✅ calcula no Java se a BD ainda não propagou
    dto.subtotal      = item.getSubtotal() != null
            ? item.getSubtotal()
            : item.getPrecoUnitario().multiply(BigDecimal.valueOf(item.getQuantidade()));
    return dto;
}

private ItemServicoResponseDTO toItemServicoResponseDTO(ItemPedidoServico item) {
    ItemServicoResponseDTO dto = new ItemServicoResponseDTO();
    dto.idItemServico  = item.getIdItemServico();
    dto.idServico      = item.getIdServico();
    dto.nomeServico    = item.getServico() != null ? item.getServico().getNomeServico() : null;
    dto.quantidade     = item.getQuantidade();
    dto.precoUnitario  = item.getPrecoUnitario();
    // ✅ calcula no Java se a BD ainda não propagou
    dto.subtotal       = item.getSubtotal() != null
            ? item.getSubtotal()
            : item.getPrecoUnitario().multiply(BigDecimal.valueOf(item.getQuantidade()));
    dto.observacoes    = item.getObservacoes();
    return dto;
}
}