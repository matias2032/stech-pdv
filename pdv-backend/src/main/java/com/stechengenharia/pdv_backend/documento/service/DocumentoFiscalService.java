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
import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
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

                var dto = DocumentoResponse.from(doc);

                return new DocumentoResponse(
                        dto.id(),
                        dto.tipoDocumento(),
                        dto.idPedido(),
                        dto.referencia(),
                        dto.numeroSeq(),
                        dto.ano(),
                        dto.codigoAt(),
                        dto.idUsuario(),
                        dto.nomeUsuario(),
                        dto.emitidoEm(),
                        dto.anulado(),
                        dto.motivoAnulacao(),

                        // 🔥 aqui injectamos
                        tipoVenda
                );
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

    // A função PL/pgSQL faz INSERT direto — o JPA não disparou @PrePersist
    // Forçamos o syncStatus manualmente após o facto
    doc.setSyncStatus("PENDING_CREATE");
    documentoRepository.save(doc);

    return DocumentoResponse.from(doc);
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

    List<ExtractoDocumentalClienteResponseDTO.LinhaDocumentalDTO> linhas =
        documentos.stream().map(d -> new ExtractoDocumentalClienteResponseDTO.LinhaDocumentalDTO(
            d.getId(),
            d.getReferencia(),
            d.getTipoDocumento().getCodigo(),
            d.getIdPedido(),
            refPorPedido.getOrDefault(d.getIdPedido(), "—"),
            d.getEmitidoEm(),
            totalPorPedido.getOrDefault(d.getIdPedido(), BigDecimal.ZERO)
        )).toList();

    BigDecimal somaTotal = linhas.stream()
        .map(ExtractoDocumentalClienteResponseDTO.LinhaDocumentalDTO::valorTotal)
        .reduce(BigDecimal.ZERO, BigDecimal::add);

    String nomeCliente = (cliente.getNome() != null ? cliente.getNome() : "")
        + (cliente.getApelido() != null ? " " + cliente.getApelido() : "");

// DEPOIS
    return new ExtractoDocumentalClienteResponseDTO(
        idCliente,
        nomeCliente.trim(),
        linhas.size(),
        somaTotal,
        linhas
    );
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

    documentoRepository.findById(idDocumentoOrigem)
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

    log.info("Nota retificativa {} emitida | documento origem {} | motivo={} | valor={}",
            doc.getReferencia(), idDocumentoOrigem, request.motivo(), request.valor());

    return new NotaRetificativaResponse(
            DocumentoResponse.from(doc),
            idDocumentoOrigem,
            request.motivo(),
            request.valor()
    );
}
}