package com.stechengenharia.pdv_backend.documento.repository;

import com.stechengenharia.pdv_backend.documento.entity.DocumentoFiscal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface DocumentoFiscalRepository extends JpaRepository<DocumentoFiscal, Integer> {

    // ── Queries existentes — sem alterações ──────────────────────────
    List<DocumentoFiscal> findByIdPedido(Integer idPedido);
    List<DocumentoFiscal> findByAnulado(Boolean anulado);
    Optional<DocumentoFiscal> findByReferencia(String referencia);
    boolean existsByReferencia(String referencia);
    List<DocumentoFiscal> findByTipoDocumento_Id(Integer idTipoDoc);

    // ── Sync ─────────────────────────────────────────────────────────
    // Documentos fiscais não têm soft delete operacional (deleted=false sempre)
    // mas precisam de PUSH para a nuvem após emissão ou anulação
    List<DocumentoFiscal> findBySyncStatusIn(List<String> statuses);
}