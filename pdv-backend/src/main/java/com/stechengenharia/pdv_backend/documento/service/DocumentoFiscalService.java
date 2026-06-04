package com.stechengenharia.pdv_backend.documento.service;

import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.AnularDocumentoRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.EmitirDocumentoMultiplosRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalRequest.EmitirDocumentoRequest;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalResponse.DocumentoResponse;
import com.stechengenharia.pdv_backend.documento.dto.DocumentoFiscalResponse.TipoDocumentoResponse;
import com.stechengenharia.pdv_backend.documento.entity.DocumentoFiscal;
import com.stechengenharia.pdv_backend.documento.entity.TipoDocumentoFiscal;
import com.stechengenharia.pdv_backend.documento.exception.DocumentoFiscalNotFoundException;
import com.stechengenharia.pdv_backend.documento.exception.DocumentoJaAnuladoException;
import com.stechengenharia.pdv_backend.documento.exception.TipoDocumentoNotFoundException;
import com.stechengenharia.pdv_backend.documento.repository.DocumentoFiscalRepository;
import com.stechengenharia.pdv_backend.documento.repository.TipoDocumentoFiscalRepository;
import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Service
@RequiredArgsConstructor
public class DocumentoFiscalService {

    private final DocumentoFiscalRepository documentoRepository;
    private final TipoDocumentoFiscalRepository tipoDocumentoRepository;

    @PersistenceContext
    private EntityManager entityManager;

    // ─── LISTAR TODOS ────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<DocumentoResponse> listarTodos() {
        return documentoRepository.findAll()
                .stream()
                .map(DocumentoResponse::from)
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
}