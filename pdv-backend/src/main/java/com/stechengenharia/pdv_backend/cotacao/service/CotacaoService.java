package com.stechengenharia.pdv_backend.cotacao.service;

import com.stechengenharia.pdv_backend.cliente.entity.Cliente;
import com.stechengenharia.pdv_backend.cliente.repository.ClienteRepository;
import com.stechengenharia.pdv_backend.cotacao.dto.CotacaoRequestDTO;
import com.stechengenharia.pdv_backend.cotacao.dto.CotacaoResponseDTO;
import com.stechengenharia.pdv_backend.cotacao.entity.Cotacao;
import com.stechengenharia.pdv_backend.cotacao.entity.CotacaoItemProduto;
import com.stechengenharia.pdv_backend.cotacao.entity.CotacaoItemServico;
import com.stechengenharia.pdv_backend.cotacao.exception.CotacaoNaoEncontradaException;
import com.stechengenharia.pdv_backend.cotacao.exception.CotacaoNaoEditavelException;
import com.stechengenharia.pdv_backend.cotacao.exception.CotacaoSemItensException;
import com.stechengenharia.pdv_backend.cotacao.exception.ItemCotacaoNaoEncontradoException;
import com.stechengenharia.pdv_backend.cotacao.repository.CotacaoItemProdutoRepository;
import com.stechengenharia.pdv_backend.cotacao.repository.CotacaoItemServicoRepository;
import com.stechengenharia.pdv_backend.cotacao.repository.CotacaoRepository;
import com.stechengenharia.pdv_backend.pedido.dto.ItemPedidoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.ItemServicoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.PedidoRequestDTO;
import com.stechengenharia.pdv_backend.pedido.dto.PedidoResponseDTO;
import com.stechengenharia.pdv_backend.pedido.service.PedidoService;
import com.stechengenharia.pdv_backend.produto.entity.Produto;
import com.stechengenharia.pdv_backend.produto.repository.ProdutoRepository;
import com.stechengenharia.pdv_backend.servico.entity.Servico;
import com.stechengenharia.pdv_backend.servico.service.ServicoService;
import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import com.stechengenharia.pdv_backend.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CotacaoService {

    // ── Repositórios próprios ─────────────────────────────────────────
    private final CotacaoRepository              cotacaoRepository;
    private final CotacaoItemProdutoRepository   itemProdutoRepository;
    private final CotacaoItemServicoRepository   itemServicoRepository;

    // ── Repositórios cross-module (só leitura / validação) ────────────
    private final ClienteRepository  clienteRepository;
    private final UsuarioRepository  usuarioRepository;
    private final ProdutoRepository  produtoRepository;

    // ── Serviços cross-module ─────────────────────────────────────────
    private final ServicoService servicoService;  // valida serviço activo
    private final PedidoService  pedidoService;   // usado apenas na conversão
    private final com.stechengenharia.pdv_backend.pedido.repository.PedidoRepository pedidoRepository;

    // ════════════════════════════════════════════════════════════════════
    // a) CRIAR COTAÇÃO
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public CotacaoResponseDTO.Detalhe criarCotacao(CotacaoRequestDTO.Criar dto) {
        log.info("Criando cotação para utilizador {}", dto.idUsuario());

        Usuario usuario = encontrarUsuarioOuLancar(dto.idUsuario());
        Cliente cliente = dto.idCliente() != null
                ? encontrarClienteOuLancar(dto.idCliente())
                : null;

        Cotacao cotacao = Cotacao.builder()
                .referencia(gerarReferencia())
                .usuario(usuario)
                .cliente(cliente)
                .statusCotacao("ABERTA")
                .total(BigDecimal.ZERO)
                .validadeAte(dto.validadeAte())
                .observacoes(dto.observacoes())
                .syncStatus("PENDING_CREATE")
                .build();

        cotacaoRepository.save(cotacao);

        log.info("Cotação {} criada", cotacao.getReferencia());
        return toDetalhe(cotacao);
    }

    // ════════════════════════════════════════════════════════════════════
    // b) LISTAR COTAÇÕES
    // ════════════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public List<CotacaoResponseDTO.Detalhe> listarTodas() {
        return cotacaoRepository.findAllAtivas()
                .stream()
                .map(this::toDetalhe)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CotacaoResponseDTO.Detalhe> listarPorStatus(String status) {
        return cotacaoRepository.findByStatus(status)
                .stream()
                .map(this::toDetalhe)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CotacaoResponseDTO.Detalhe> listarPorCliente(Long idCliente) {
        return cotacaoRepository.findByClienteId(idCliente)
                .stream()
                .map(this::toDetalhe)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<CotacaoResponseDTO.Detalhe> listarPorUsuario(Long idUsuario) {
        return cotacaoRepository.findByUsuarioId(idUsuario)
                .stream()
                .map(this::toDetalhe)
                .toList();
    }

    @Transactional(readOnly = true)
public List<CotacaoResponseDTO.Detalhe> listarProntas() {
    return cotacaoRepository.findAllProntas()
            .stream()
            .map(this::toDetalhe)
            .toList();
}

    // ════════════════════════════════════════════════════════════════════
    // c) VISUALIZAR COTAÇÃO
    // ════════════════════════════════════════════════════════════════════

    @Transactional(readOnly = true)
    public CotacaoResponseDTO.Detalhe buscarPorId(Long idCotacao) {
        return toDetalhe(encontrarCotacaoCompletaOuLancar(idCotacao));
    }

    // ════════════════════════════════════════════════════════════════════
    // d) ACTUALIZAR COTAÇÃO
    // ════════════════════════════════════════════════════════════════════

@Transactional
public CotacaoResponseDTO.Detalhe atualizarCotacao(Long idCotacao, CotacaoRequestDTO.Atualizar dto) {
    Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);

    // Transição de status — permitida independentemente de editabilidade
    if (dto.statusCotacao() != null) {
        validarTransicaoManual(cotacao.getStatusCotacao(), dto.statusCotacao());
        cotacao.setStatusCotacao(dto.statusCotacao());
        cotacao.setSyncStatus("PENDING_UPDATE");
        cotacaoRepository.save(cotacao);
        log.info("Status da cotação {} alterado para {}", cotacao.getReferencia(), dto.statusCotacao());
        return toDetalhe(cotacao);
    }

    // Restantes campos — exigem estado editável (ABERTA)
    validarEditavel(cotacao, "actualização");

    if (dto.idCliente() != null) {
        cotacao.setCliente(encontrarClienteOuLancar(dto.idCliente()));
    } else {
        cotacao.setCliente(null);
    }
    if (dto.validadeAte() != null) cotacao.setValidadeAte(dto.validadeAte());
    if (dto.observacoes() != null) cotacao.setObservacoes(dto.observacoes());

    cotacao.setSyncStatus("PENDING_UPDATE");
    cotacaoRepository.save(cotacao);

    log.info("Cotação {} actualizada", cotacao.getReferencia());
    return toDetalhe(cotacao);
}

    // ════════════════════════════════════════════════════════════════════
    // e) SOFT DELETE
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public void excluirCotacao(Long idCotacao) {
        Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);
        validarEditavel(cotacao, "eliminação");

        cotacao.setDeleted(true);
        cotacao.setSyncStatus("PENDING_DELETE");
        cotacaoRepository.save(cotacao);

        log.info("Cotação {} marcada como eliminada", cotacao.getReferencia());
    }

    // ════════════════════════════════════════════════════════════════════
    // f) ADICIONAR ITEM DE PRODUTO
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public CotacaoResponseDTO.Detalhe adicionarProduto(Long idCotacao, CotacaoRequestDTO.AdicionarProduto dto) {
        Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);
        validarEditavel(cotacao, "adição de produto");

        Produto produto = produtoRepository.findById(dto.idProduto())
                .orElseThrow(() -> new IllegalArgumentException(
                        "Produto não encontrado: " + dto.idProduto()));

        // preço: usa o do DTO se vier; caso contrário copia do catálogo
        BigDecimal preco = dto.precoUnitario() != null
                ? dto.precoUnitario()
                : (produto.getPrecoPromocional() != null
                        ? produto.getPrecoPromocional()
                        : produto.getPreco());

        // se já existe, incrementa quantidade em vez de duplicar linha
        itemProdutoRepository
                .findByCotacaoIdAndProdutoIdProduto(idCotacao, dto.idProduto())
                .ifPresentOrElse(
                        item -> {
                            item.setQuantidade(item.getQuantidade() + dto.quantidade());
                            item.setPrecoUnitario(preco);
                            itemProdutoRepository.save(item);
                            log.info("Produto {} incrementado na cotação {}", dto.idProduto(), idCotacao);
                        },
                        () -> {
                            CotacaoItemProduto item = CotacaoItemProduto.builder()
                                    .cotacao(cotacao)
                                    .produto(produto)
                                    .quantidade(dto.quantidade())
                                    .precoUnitario(preco)
                                    .observacoes(dto.observacoes())
                                    .build();
                            itemProdutoRepository.save(item);
                            cotacao.getItensProduto().add(item);
                            log.info("Produto {} adicionado à cotação {}", dto.idProduto(), idCotacao);
                        }
                );

        cotacao.recalcularTotal();
        cotacao.setSyncStatus("PENDING_UPDATE");
        cotacaoRepository.save(cotacao);

        return toDetalhe(cotacao);
    }

    // ════════════════════════════════════════════════════════════════════
    // g) ADICIONAR ITEM DE SERVIÇO
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public CotacaoResponseDTO.Detalhe adicionarServico(Long idCotacao, CotacaoRequestDTO.AdicionarServico dto) {
        Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);
        validarEditavel(cotacao, "adição de serviço");

        Servico servico = servicoService.validarServicoDisponivel(dto.idServico().intValue());
        
        BigDecimal preco = dto.precoUnitario() != null
                ? dto.precoUnitario()
                : servico.getPrecoUnitario();

        // se já existe, incrementa quantidade em vez de duplicar linha
       itemServicoRepository
    .findByCotacaoIdAndServicoIdServico(idCotacao, dto.idServico().intValue())
    .ifPresentOrElse(
                        item -> {
                            item.setQuantidade(item.getQuantidade() + dto.quantidade());
                            item.setPrecoUnitario(preco);
                            itemServicoRepository.save(item);
                            log.info("Serviço {} incrementado na cotação {}", dto.idServico(), idCotacao);
                        },
                        () -> {
                            CotacaoItemServico item = CotacaoItemServico.builder()
                                    .cotacao(cotacao)
                                    .servico(servico)
                                    .quantidade(dto.quantidade())
                                    .precoUnitario(preco)
                                    .observacoes(dto.observacoes())
                                    .build();
                            itemServicoRepository.save(item);
                            cotacao.getItensServico().add(item);
                            log.info("Serviço {} adicionado à cotação {}", dto.idServico(), idCotacao);
                        }
                );

        cotacao.recalcularTotal();
        cotacao.setSyncStatus("PENDING_UPDATE");
        cotacaoRepository.save(cotacao);

        return toDetalhe(cotacao);
    }

    // ════════════════════════════════════════════════════════════════════
    // h) ACTUALIZAR ITEM DE PRODUTO
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public CotacaoResponseDTO.Detalhe atualizarItemProduto(
            Long idCotacao, Long idItem, CotacaoRequestDTO.AtualizarItem dto) {

        Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);
        validarEditavel(cotacao, "actualização de item de produto");

        CotacaoItemProduto item = itemProdutoRepository
                .findByIdECotacao(idItem, idCotacao)
                .orElseThrow(() -> new ItemCotacaoNaoEncontradoException(idItem, idCotacao));

        int anterior = item.getQuantidade();
        item.setQuantidade(dto.quantidade());

        if (dto.precoUnitario() != null) {
            item.setPrecoUnitario(dto.precoUnitario());
        }
        if (dto.observacoes() != null) {
            item.setObservacoes(dto.observacoes());
        }

        itemProdutoRepository.save(item);

        cotacao.recalcularTotal();
        cotacao.setSyncStatus("PENDING_UPDATE");
        cotacaoRepository.save(cotacao);

        log.info("Item produto {} da cotação {}: {} → {} unidades",
                idItem, idCotacao, anterior, dto.quantidade());

        return toDetalhe(cotacao);
    }

    // ════════════════════════════════════════════════════════════════════
    // i) ACTUALIZAR ITEM DE SERVIÇO
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public CotacaoResponseDTO.Detalhe atualizarItemServico(
            Long idCotacao, Long idItem, CotacaoRequestDTO.AtualizarItem dto) {

        Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);
        validarEditavel(cotacao, "actualização de item de serviço");

        CotacaoItemServico item = itemServicoRepository
                .findByIdECotacao(idItem, idCotacao)
                .orElseThrow(() -> new ItemCotacaoNaoEncontradoException(idItem, idCotacao));

        int anterior = item.getQuantidade();
        item.setQuantidade(dto.quantidade());

        if (dto.precoUnitario() != null) {
            item.setPrecoUnitario(dto.precoUnitario());
        }
        if (dto.observacoes() != null) {
            item.setObservacoes(dto.observacoes());
        }

        itemServicoRepository.save(item);

        cotacao.recalcularTotal();
        cotacao.setSyncStatus("PENDING_UPDATE");
        cotacaoRepository.save(cotacao);

        log.info("Item serviço {} da cotação {}: {} → {} unidades",
                idItem, idCotacao, anterior, dto.quantidade());

        return toDetalhe(cotacao);
    }

    // ════════════════════════════════════════════════════════════════════
    // j) REMOVER ITEM DE PRODUTO
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public CotacaoResponseDTO.Detalhe removerItemProduto(Long idCotacao, Long idItem) {
        Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);
        validarEditavel(cotacao, "remoção de item de produto");

        CotacaoItemProduto item = itemProdutoRepository
                .findByIdECotacao(idItem, idCotacao)
                .orElseThrow(() -> new ItemCotacaoNaoEncontradoException(idItem, idCotacao));

        cotacao.getItensProduto().remove(item);
        itemProdutoRepository.delete(item);

        cotacao.recalcularTotal();
        cotacao.setSyncStatus("PENDING_UPDATE");
        cotacaoRepository.save(cotacao);

        log.info("Item produto {} removido da cotação {}", idItem, idCotacao);
        return toDetalhe(cotacao);
    }

    // ════════════════════════════════════════════════════════════════════
    // k) REMOVER ITEM DE SERVIÇO
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public CotacaoResponseDTO.Detalhe removerItemServico(Long idCotacao, Long idItem) {
        Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);
        validarEditavel(cotacao, "remoção de item de serviço");

        CotacaoItemServico item = itemServicoRepository
                .findByIdECotacao(idItem, idCotacao)
                .orElseThrow(() -> new ItemCotacaoNaoEncontradoException(idItem, idCotacao));

        cotacao.getItensServico().remove(item);
        itemServicoRepository.delete(item);

        cotacao.recalcularTotal();
        cotacao.setSyncStatus("PENDING_UPDATE");
        cotacaoRepository.save(cotacao);

        log.info("Item serviço {} removido da cotação {}", idItem, idCotacao);
        return toDetalhe(cotacao);
    }

    // ════════════════════════════════════════════════════════════════════
    // l) CONVERTER COTAÇÃO EM PEDIDO
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public PedidoResponseDTO converterEmPedido(Long idCotacao, CotacaoRequestDTO.ConverterEmPedido dto) {
        Cotacao cotacao = encontrarCotacaoCompletaOuLancar(idCotacao);

        // ── Guardas ───────────────────────────────────────────────────
    if (!"PRONTA".equals(cotacao.getStatusCotacao())) {
    throw new CotacaoNaoEditavelException(
        "Só cotações com status PRONTA podem ser convertidas. " +
        "Status actual: " + cotacao.getStatusCotacao());
}
if (!cotacao.temItens()) {
    throw new CotacaoSemItensException(cotacao.getReferencia());
}

        // ── Monta PedidoRequestDTO a partir da cotação ────────────────
        PedidoRequestDTO pedidoRequest = new PedidoRequestDTO();
        pedidoRequest.idUsuario       = cotacao.getUsuario().getId().intValue();
        pedidoRequest.idTipoPagamento = dto.idTipoPagamento();
        pedidoRequest.observacoes     = dto.observacoes() != null
                ? dto.observacoes()
                : cotacao.getObservacoes();

        pedidoRequest.itensProduto = cotacao.getItensProduto().stream()
                .map(item -> {
                    ItemPedidoRequestDTO i = new ItemPedidoRequestDTO();
                    i.idProduto  = item.getProduto().getIdProduto();
                    i.quantidade = item.getQuantidade();
                    return i;
                }).toList();

        pedidoRequest.itensServico = cotacao.getItensServico().stream()
                .map(item -> {
                    ItemServicoRequestDTO i = new ItemServicoRequestDTO();
                    i.idServico  = item.getServico().getIdServico().intValue();
                    i.quantidade = item.getQuantidade();
                    i.observacoes = item.getObservacoes();
                    return i;
                }).toList();

        // ── Cria o pedido via PedidoService ───────────────────────────
        PedidoResponseDTO pedidoResponse = pedidoService.criarPedido(pedidoRequest);

        // ── Marca cotação como CONVERTIDA ─────────────────────────────
        cotacao.setStatusCotacao("CONVERTIDA");
        cotacao.setSyncStatus("PENDING_UPDATE");

        // guarda referência ao pedido gerado
        // (lookup leve — só o proxy JPA, sem JOIN)
        cotacaoRepository.findById(idCotacao).ifPresent(c -> {
            // pedidoConvertido é carregado via referência
        });
        // usa o ID retornado pelo pedidoService para evitar dependência circular
      
             cotacao.setPedidoConvertido(pedidoRepository.getReferenceById(pedidoResponse.idPedido));

        cotacaoRepository.save(cotacao);

        log.info("Cotação {} convertida no pedido {}",
                cotacao.getReferencia(), pedidoResponse.referencia);

        return pedidoResponse;
    }

    // ════════════════════════════════════════════════════════════════════
    // m) MARCAR EXPIRADAS (chamado por @Scheduled)
    // ════════════════════════════════════════════════════════════════════

    @Transactional
    public void marcarExpiradas() {
        List<Cotacao> expiradas = cotacaoRepository.findExpiradas(LocalDate.now());
        expiradas.forEach(c -> {
            c.setStatusCotacao("EXPIRADA");
            c.setSyncStatus("PENDING_UPDATE");
            log.info("Cotação {} marcada como EXPIRADA (validade: {})",
                    c.getReferencia(), c.getValidadeAte());
        });
        cotacaoRepository.saveAll(expiradas);
    }

    // ════════════════════════════════════════════════════════════════════
    // HELPERS PRIVADOS
    // ════════════════════════════════════════════════════════════════════

    private Cotacao encontrarCotacaoCompletaOuLancar(Long idCotacao) {
        return cotacaoRepository.findByIdCompleto(idCotacao)
                .orElseThrow(() -> new CotacaoNaoEncontradaException(idCotacao));
    }

    private Usuario encontrarUsuarioOuLancar(Long idUsuario) {
        return usuarioRepository.findById(idUsuario)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Utilizador não encontrado: " + idUsuario));
    }

    private Cliente encontrarClienteOuLancar(Long idCliente) {
        return clienteRepository.findById(idCliente)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Cliente não encontrado: " + idCliente));
    }

    private void validarEditavel(Cotacao cotacao, String operacao) {
        if (!cotacao.isEditavel()) {
            throw new CotacaoNaoEditavelException(
                    "Cotação " + cotacao.getReferencia() +
                    " está " + cotacao.getStatusCotacao() +
                    " — operação não permitida: " + operacao);
        }
    }

private void validarTransicaoManual(String statusActual, String novoStatus) {
    List<String> permitidos = switch (statusActual) {
        case "ABERTA"  -> List.of("PRONTA", "CANCELADA");
        case "PRONTA"  -> List.of("ABERTA", "CANCELADA");
        default        -> List.of();
    };
    if (!permitidos.contains(novoStatus)) {
        throw new IllegalArgumentException(
            "Transição de status inválida: " + statusActual + " → " + novoStatus);
    }
}

    private String gerarReferencia() {
        return "COT-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    // ── Mapeamento entity → DTO ───────────────────────────────────────

    private CotacaoResponseDTO.Detalhe toDetalhe(Cotacao c) {
        return new CotacaoResponseDTO.Detalhe(c);
    }
}

