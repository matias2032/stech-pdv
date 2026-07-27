package com.stechengenharia.pdv_backend.documento.repository;

import com.stechengenharia.pdv_backend.documento.entity.DocumentoFiscal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import com.stechengenharia.pdv_backend.pedido.entity.Pedido;
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
    @Query("""
    SELECT d, p.tipoVenda
    FROM DocumentoFiscal d
    JOIN Pedido p ON p.idPedido = d.idPedido
""")
List<Object[]> findAllWithTipoVenda();


@Query("""
    SELECT d FROM DocumentoFiscal d
    JOIN FETCH d.tipoDocumento t
    WHERE d.idPedido IN (
        SELECT p.idPedido FROM Pedido p
        WHERE p.idCliente = :idCliente
          AND p.deleted = false
    )
    AND t.codigo IN ('FAT', 'VD')
    AND d.anulado = false
    ORDER BY d.emitidoEm DESC
""")
List<DocumentoFiscal> findFacturasEVdsPorCliente(@Param("idCliente") Long idCliente);
}

