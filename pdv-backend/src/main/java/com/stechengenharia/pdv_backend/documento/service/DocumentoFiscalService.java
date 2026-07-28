package com.stechengenharia.pdv_backend.documento.service;


import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.AnularDocumentoRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.EmitirDocumentoMultiplosRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.EmitirDocumentoRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.EmitirNotaRetificativaRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalResponse.DocumentoResponse;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalResponse.NotaRetificativaResponse;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalResponse.TipoDocumentoResponse;
import com.stechengenharia.pdv_backend.documento.entity.DocumentoFiscal;
import com.stechengenharia.pdv_backend.documento.entity.TipoDocumentoFiscal;
import com.stechengenharia.pdv_backend.documento.exception.DocumentoFiscalNotFoundException;
import com.stechengenharia.pdv_backend.documento.exception.DocumentoJaAnuladoException;
import com.stechengenharia.pdv_backend.documento.exception.DocumentoJaSincronizadoException;
import com.stechengenharia.pdv_backend.documento.exception.TipoDocumentoNotFoundException;
import com.stechengenharia.pdv_backend.documento.repository.DocumentoFiscalRepository;
import com.stechengenharia.pdv_backend.documento.repository.TipoDocumentoFiscalRepository;
import com.stechengenharia.pdv_backend.pedido.entity.DocumentoFiscalRelacao;
import com.stechengenharia.pdv_backend.pedido.repository.DocumentoFiscalRelacaoRepository;
import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import java.util.Objects;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.stechengenharia.pdv_backend.cliente.repository.ClienteRepository;
import com.stechengenharia.pdv_backend.cliente.entity.Cliente;
import com.stechengenharia.pdv_backend.pedido.repository.PedidoRepository;
import com.stechengenharia.pdv_backend.pedido.entity.Pedido;
import com.stechengenharia.pdv_backend.documento.dto.ExtractoDocumentalClienteResponseDTO;
import java.math.BigDecimal;
import java.util.List;
import java.util.Map;


@Slf4j
@Service
@RequiredArgsConstructor
public class DocumentoFiscalService {

    private final DocumentoFiscalRepository documentoRepository;
    private final TipoDocumentoFiscalRepository tipoDocumentoRepository;
    private final ClienteRepository clienteRepository;
    private final PedidoRepository pedidoRepository;
    private final DocumentoFiscalRelacaoRepository relacaoRepository;

    @PersistenceContext
    private EntityManager entityManager;

    // ─── LISTAR TODOS ────────────────────────────────────────────────────────

@Transactional(readOnly = true)
public List<DocumentoResponse> listarTodos() {
    return documentoRepository.findAllWithTipoVenda()
            .stream()
            .map(obj -> {
                DocumentoFiscal doc = (DocumentoFiscal) obj[0];
                String tipoVenda = (String) obj[1];

                // ✅ Usa o método customizado passando o tipoVenda injetado
                return DocumentoResponse.from(doc, tipoVenda);
            })
            .toList();
}

    // ─── BUSCAR POR ID ───────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public DocumentoResponse buscarPorId(Integer id) {
        DocumentoFiscal doc = documentoRepository.findById(id)
                .orElseThrow(() -> new DocumentoFiscalNotFoundException(id));
        return DocumentoResponse.from(doc);
    }

    // ─── BUSCAR POR REFERÊNCIA ───────────────────────────────────────────────

    @Transactional(readOnly = true)
    public DocumentoResponse buscarPorReferencia(String referencia) {
        DocumentoFiscal doc = documentoRepository.findByReferencia(referencia)
                .orElseThrow(() -> new DocumentoFiscalNotFoundException(referencia));
        return DocumentoResponse.from(doc);
    }

    // ─── LISTAR POR PEDIDO ───────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<DocumentoResponse> listarPorPedido(Integer idPedido) {
        return documentoRepository.findByIdPedido(idPedido)
                .stream()
                .map(DocumentoResponse::from)
                .toList();
    }

    // ─── LISTAR POR TIPO ─────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<DocumentoResponse> listarPorTipo(Integer idTipoDoc) {
        return documentoRepository.findByTipoDocumento_Id(idTipoDoc)
                .stream()
                .map(DocumentoResponse::from)
                .toList();
    }

    // ─── EMITIR (CREATE via function PL/pgSQL) ───────────────────────────────

    /**
     * Delega na função PostgreSQL emitir_documento_fiscal() para garantir
     * atomicidade na geração da sequência e da referência.
     */
@Transactional
public DocumentoResponse emitir(EmitirDocumentoRequest request) {
    tipoDocumentoRepository.findByCodigo(request.codigoTipo())
            .orElseThrow(() -> new TipoDocumentoNotFoundException(request.codigoTipo()));

    DocumentoFiscal doc = (DocumentoFiscal) entityManager
            .createNativeQuery(
                    "SELECT * FROM emitir_documento_fiscal(:idPedido, :codigoTipo, :idUsuario, :codigoAt)",
                    DocumentoFiscal.class
            )
            .setParameter("idPedido",   request.idPedido())
            .setParameter("codigoTipo", request.codigoTipo())
            .setParameter("idUsuario",  request.idUsuario().intValue())
            .setParameter("codigoAt",   request.codigoAt())
            .getSingleResult();

    doc.setSyncStatus("PENDING_CREATE");

    // Documentos "originais" (FAT/VD) congelam o conteúdo do pedido no
    // momento da emissão — o PDF passa a ler daqui, não do pedido ao vivo.
String codigo = doc.getTipoDocumento().getCodigo();
    if ("FAT".equals(codigo) || "VD".equals(codigo)) {
        pedidoRepository.findById(request.idPedido())
  .ifPresentOrElse(pedido -> {
            // força inicialização das coleções lazy dentro da transação
            pedido.getItensProduto().size();
            pedido.getItensServico().size();
            doc.setSnapshotConteudo(gerarSnapshotPedido(pedido));
            doc.setValorTotalEmissao(pedido.getTotal());
        }, () -> log.warn("Pedido {} não encontrado ao emitir doc fiscal — snapshot não gerado", request.idPedido()));
    }

    documentoRepository.save(doc);

    return DocumentoResponse.from(doc);
}

/**
 * Serializa em JSON os dados imutáveis do pedido (itens, preços, total)
 * no instante da emissão da factura. Usado pela geração de PDF para que
 * a factura nunca reflicta alterações posteriores ao pedido.
 */
private String gerarSnapshotPedido(Pedido pedido) {
    try {
        var itens = pedido.getItensProduto().stream()
                .map(i -> Map.of(
                        "produto", i.getProduto().getNomeProduto(),
                        "quantidade", i.getQuantidade(),
                        "precoUnitario", i.getPrecoUnitario(),
                        "subtotal", i.getSubtotal()
                )).toList();

        var servicos = pedido.getItensServico().stream()
                .map(i -> Map.of(
                        "servico", i.getServico() != null ? i.getServico().getNomeServico() : null,
                        "quantidade", i.getQuantidade(),
                        "precoUnitario", i.getPrecoUnitario(),
                        "subtotal", i.getSubtotal()
                )).toList();

        Map<String, Object> snapshot = Map.of(
                "referenciaPedido", pedido.getReferencia(),
                "total", pedido.getTotal(),
                "itensProduto", itens,
                "itensServico", servicos
        );

        return new com.fasterxml.jackson.databind.ObjectMapper().writeValueAsString(snapshot);
    } catch (Exception e) {
        log.error("Falha ao gerar snapshot do pedido {} para documento fiscal", pedido.getIdPedido(), e);
        return null;
    }
}

    // ─── ANULAR ───────────────────────────────────────────────────────────────

@Transactional
public DocumentoResponse anular(Integer id, AnularDocumentoRequest request) {
    DocumentoFiscal doc = documentoRepository.findById(id)
            .orElseThrow(() -> new DocumentoFiscalNotFoundException(id));

    if (Boolean.TRUE.equals(doc.getAnulado())) {
        throw new DocumentoJaAnuladoException(doc.getReferencia());
    }

    String codigoTipo = doc.getTipoDocumento().getCodigo();
    boolean isFaturaOuVd = "FAT".equals(codigoTipo) || "VD".equals(codigoTipo);
    if (isFaturaOuVd && "SYNCED".equals(doc.getSyncStatus())) {
        throw new DocumentoJaSincronizadoException(doc.getReferencia());
    }

    doc.setAnulado(true);
    doc.setMotivoAnulacao(request.motivoAnulacao());
    doc.setSyncStatus("PENDING_UPDATE"); // anulação deve chegar à nuvem
    // @PreUpdate seria suficiente se syncStatus=SYNCED, mas pode estar PENDING_CREATE ainda

    return DocumentoResponse.from(documentoRepository.save(doc));
}

    // ─── ELIMINAR ─────────────────────────────────────────────────────────────

@Transactional
public void eliminar(Integer id) {
    DocumentoFiscal doc = documentoRepository.findById(id)
            .orElseThrow(() -> new DocumentoFiscalNotFoundException(id));
    // Documentos fiscais não devem ser eliminados fisicamente (rastreabilidade legal)
    // Soft delete: marca como deleted + PENDING_DELETE para a nuvem saber
    doc.setDeleted(true);
    doc.setSyncStatus("PENDING_DELETE");
    documentoRepository.save(doc);
}

    // ─── TIPOS DE DOCUMENTO (leitura) ────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<TipoDocumentoResponse> listarTipos() {
        return tipoDocumentoRepository.findAll()
                .stream()
                .map(t -> new TipoDocumentoResponse(t.getId(), t.getCodigo(), t.getNome(), t.getPrefixo()))
                .toList();
    }

    @Transactional(readOnly = true)
    public TipoDocumentoResponse buscarTipoPorId(Integer id) {
        TipoDocumentoFiscal tipo = tipoDocumentoRepository.findById(id)
                .orElseThrow(() -> new TipoDocumentoNotFoundException(id));
        return new TipoDocumentoResponse(tipo.getId(), tipo.getCodigo(), tipo.getNome(), tipo.getPrefixo());
    }

@Transactional
public DocumentoResponse emitirMultiplos(EmitirDocumentoMultiplosRequest request) {
    tipoDocumentoRepository.findByCodigo(request.codigoTipo())
            .orElseThrow(() -> new TipoDocumentoNotFoundException(request.codigoTipo()));

    List<Integer> ids = request.idsPedido();

    DocumentoFiscal doc = (DocumentoFiscal) entityManager
            .createNativeQuery(
                    "SELECT * FROM emitir_documento_fiscal_multiplos(CAST(:idsPedido AS integer[]), :codigoTipo, :idUsuario, :codigoAt)",
                    DocumentoFiscal.class
            )
            .setParameter("idsPedido", ids.stream()
                    .map(String::valueOf)
                    .collect(java.util.stream.Collectors.joining(",", "{", "}")))
            .setParameter("codigoTipo", request.codigoTipo())
            .setParameter("idUsuario",  request.idUsuario().intValue())
            .setParameter("codigoAt",   request.codigoAt())
            .getSingleResult();

    doc.setSyncStatus("PENDING_CREATE"); // mesma razão que emitir()
    documentoRepository.save(doc);

    return DocumentoResponse.from(doc);
}

@Transactional(readOnly = true)
public ExtractoDocumentalClienteResponseDTO extractoDocumentalCliente(Long idCliente) {
    Cliente cliente = clienteRepository.findById(idCliente)
        .orElseThrow(() -> new RuntimeException("Cliente não encontrado: " + idCliente));

    List<DocumentoFiscal> documentos =
        documentoRepository.findFacturasEVdsPorCliente(idCliente);

    // Mapa auxiliar para obter totais dos pedidos (valor do documento = total do pedido)
    List<Integer> idsPedido = documentos.stream()
        .map(DocumentoFiscal::getIdPedido)
        .distinct()
        .toList();

    Map<Integer, BigDecimal> totalPorPedido = pedidoRepository
        .findAllById(idsPedido)
        .stream()
        .collect(java.util.stream.Collectors.toMap(
            p -> p.getIdPedido(),
            p -> p.getTotal()
        ));

    Map<Integer, String> refPorPedido = pedidoRepository
        .findAllById(idsPedido)
        .stream()
        .collect(java.util.stream.Collectors.toMap(
            p -> p.getIdPedido(),
            p -> p.getReferencia()
        ));

// DEPOIS
List<ExtractoDocumentalClienteResponseDTO.LinhaDocumentalDTO> linhas =
        documentos.stream().map(d -> {
            // Usa o valor congelado na emissão. Só recai sobre o total ao
            // vivo do pedido para documentos antigos emitidos antes desta
            // coluna existir — nunca para documentos novos.
            BigDecimal valorTotal = d.getValorTotalEmissao() != null
                    ? d.getValorTotalEmissao()
                    : totalPorPedido.getOrDefault(d.getIdPedido(), BigDecimal.ZERO);
            BigDecimal valorAjuste = calcularAjusteDocumento(d.getId());
            BigDecimal valorLiquido = valorTotal.add(valorAjuste);

            return new ExtractoDocumentalClienteResponseDTO.LinhaDocumentalDTO(
                d.getId(),
                d.getReferencia(),
                d.getTipoDocumento().getCodigo(),
                d.getIdPedido(),
                refPorPedido.getOrDefault(d.getIdPedido(), "—"),
                d.getEmitidoEm(),
                valorTotal,
                valorAjuste,
                valorLiquido
            );
        }).toList();

    BigDecimal somaTotal = linhas.stream()
        .map(ExtractoDocumentalClienteResponseDTO.LinhaDocumentalDTO::valorTotal)
        .reduce(BigDecimal.ZERO, BigDecimal::add);

    BigDecimal somaLiquida = linhas.stream()
        .map(ExtractoDocumentalClienteResponseDTO.LinhaDocumentalDTO::valorLiquido)
        .reduce(BigDecimal.ZERO, BigDecimal::add);

    String nomeCliente = (cliente.getNome() != null ? cliente.getNome() : "")
        + (cliente.getApelido() != null ? " " + cliente.getApelido() : "");

    return new ExtractoDocumentalClienteResponseDTO(
        idCliente,
        nomeCliente.trim(),
        linhas.size(),
        somaTotal,
        somaLiquida,
        linhas
    );
}

/**
 * Calcula o ajuste líquido (débitos - créditos) das notas retificativas
 * (NCR/NDB) associadas a um documento fiscal (FAT/VD).
 * Nota: na tabela documento_fiscal_relacao, id_documento_relacionado
 * aponta para a FAT/VD de origem — id_documento_origem é a própria NCR/NDB.
 */
private BigDecimal calcularAjusteDocumento(Integer idDocumento) {
    BigDecimal creditos = relacaoRepository
        .findByIdDocumentoRelacionadoAndTipoRelacao(idDocumento, "NOTA_CREDITO")
        .stream()
        .map(DocumentoFiscalRelacao::getValor)
        .filter(Objects::nonNull)
        .reduce(BigDecimal.ZERO, BigDecimal::add);

    BigDecimal debitos = relacaoRepository
        .findByIdDocumentoRelacionadoAndTipoRelacao(idDocumento, "NOTA_DEBITO")
        .stream()
        .map(DocumentoFiscalRelacao::getValor)
        .filter(Objects::nonNull)
        .reduce(BigDecimal.ZERO, BigDecimal::add);

    return debitos.subtract(creditos);
}

// ─── NOTAS DE CRÉDITO / DÉBITO ────────────────────────────────────────────

/**
 * Emite uma Nota de Crédito (NCR) ou Nota de Débito (NDB) ligada a um
 * documento de origem, delegando na função PL/pgSQL emitir_nota_retificativa(),
 * que já grava a relação em documento_fiscal_relacao.
 */
@Transactional
public NotaRetificativaResponse emitirNotaRetificativa(
        Integer idDocumentoOrigem, EmitirNotaRetificativaRequest request) {

    DocumentoFiscal documentoOrigem = documentoRepository.findById(idDocumentoOrigem)
            .orElseThrow(() -> new DocumentoFiscalNotFoundException(idDocumentoOrigem));

    tipoDocumentoRepository.findByCodigo(request.codigoTipo())
            .orElseThrow(() -> new TipoDocumentoNotFoundException(request.codigoTipo()));

    DocumentoFiscal doc = (DocumentoFiscal) entityManager
            .createNativeQuery(
                    "SELECT * FROM emitir_nota_retificativa(:idDocumentoOrigem, :codigoTipo, " +
                    ":idUsuario, :codigoAt, :motivo, :valor, :observacoes)",
                    DocumentoFiscal.class
            )
            .setParameter("idDocumentoOrigem", idDocumentoOrigem)
            .setParameter("codigoTipo",        request.codigoTipo())
            .setParameter("idUsuario",         request.idUsuario().intValue())
            .setParameter("codigoAt",          request.codigoAt())
            .setParameter("motivo",            request.motivo())
            .setParameter("valor",             request.valor())
            .setParameter("observacoes",       request.observacoes())
            .getSingleResult();

    doc.setSyncStatus("PENDING_CREATE");
    documentoRepository.save(doc);

    // Ponto único de ajuste de saldo — cobre NCR (via PedidoService) e NDB (directo).
    aplicarAjusteSaldoPedido(documentoOrigem.getIdPedido(), request.codigoTipo(), request.valor());

    log.info("Nota retificativa {} emitida | documento origem {} | motivo={} | valor={}",
            doc.getReferencia(), idDocumentoOrigem, request.motivo(), request.valor());

    return new NotaRetificativaResponse(
            DocumentoResponse.from(doc),
            idDocumentoOrigem,
            request.motivo(),
            request.valor()
    );
}

/**
 * Aplica o efeito de uma NCR (crédito) ou NDB (débito) no saldo do pedido
 * de origem — apenas para pedidos a crédito (tipoVenda == "CREDITO").
 * Para vendas imediatas, o valor não é aplicado a nenhum saldo (não existe
 * esse conceito hoje); fica apenas registado nas colunas de auditoria.
 */
private void aplicarAjusteSaldoPedido(Integer idPedido, String codigoTipo, BigDecimal valor) {
    if (idPedido == null || valor == null || valor.compareTo(BigDecimal.ZERO) == 0) {
        return;
    }

    Pedido pedido = pedidoRepository.findById(idPedido).orElse(null);
    if (pedido == null) {
        log.warn("Nota {} emitida mas pedido {} não encontrado — ajuste de saldo ignorado.",
                codigoTipo, idPedido);
        return;
    }

    if (!"CREDITO".equalsIgnoreCase(pedido.getTipoVenda())) {
        log.info("Pedido {} não é a crédito (tipoVenda={}) — nota {} não altera saldo.",
                idPedido, pedido.getTipoVenda(), codigoTipo);
        return;
    }

    if ("NCR".equals(codigoTipo)) {
        pedido.setValorCreditadoDevolucao(
                (pedido.getValorCreditadoDevolucao() != null
                        ? pedido.getValorCreditadoDevolucao() : BigDecimal.ZERO).add(valor));
    } else if ("NDB".equals(codigoTipo)) {
        pedido.setValorDebitadoAjuste(
                (pedido.getValorDebitadoAjuste() != null
                        ? pedido.getValorDebitadoAjuste() : BigDecimal.ZERO).add(valor));
    } else {
        return; // outros tipos de documento não afectam saldo
    }

    pedido.setSyncStatus("PENDING_UPDATE");
    pedidoRepository.save(pedido);

    log.info("Pedido {} | ajuste de saldo aplicado | tipo={} | valor={} | novoCreditado={} | novoDebitado={}",
            idPedido, codigoTipo, valor,
            pedido.getValorCreditadoDevolucao(), pedido.getValorDebitadoAjuste());
}
}