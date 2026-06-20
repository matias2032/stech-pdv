package com.stechengenharia.pdv_backend.fornecedor.repository;

import com.stechengenharia.pdv_backend.fornecedor.entity.Fornecedor;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

public interface FornecedorRepository extends JpaRepository<Fornecedor, Long> {

    // ── Unicidade ignorando soft-deleted ──────────────────────────────

    boolean existsByEmailAndDeletedFalse(String email);

    boolean existsByNuitAndDeletedFalse(String nuit);

    boolean existsByContactoAndDeletedFalse(String contacto);

    boolean existsByEmailAndIdNotAndDeletedFalse(String email, Long id);

    boolean existsByNuitAndIdNotAndDeletedFalse(String nuit, Long id);

    boolean existsByContactoAndIdNotAndDeletedFalse(String contacto, Long id);

    // ── Busca por ID filtrando deletados ──────────────────────────────

    @Query("""
        SELECT f FROM Fornecedor f
        WHERE f.id = :id
          AND f.deleted = false
    """)
    Optional<Fornecedor> findByIdAtivo(@Param("id") Long id);

    // ── Listagem filtrando deletados ─────────────────────────────────

    @Query("""
        SELECT f FROM Fornecedor f
        WHERE f.deleted = false
        ORDER BY f.nome ASC
    """)
    List<Fornecedor> findAllAtivos();

    // ── Pesquisa ─────────────────────────────────────────────────────

    @Query("""
        SELECT f FROM Fornecedor f
        WHERE f.deleted = false
          AND (
                LOWER(COALESCE(f.nome, ''))     LIKE LOWER(CONCAT('%', :termo, '%'))
             OR LOWER(COALESCE(f.email, ''))    LIKE LOWER(CONCAT('%', :termo, '%'))
             OR LOWER(COALESCE(f.contacto, '')) LIKE LOWER(CONCAT('%', :termo, '%'))
             OR LOWER(COALESCE(f.nuit, ''))     LIKE LOWER(CONCAT('%', :termo, '%'))
             OR LOWER(COALESCE(f.morada, ''))   LIKE LOWER(CONCAT('%', :termo, '%'))
          )
        ORDER BY f.nome ASC
    """)
    List<Fornecedor> pesquisar(@Param("termo") String termo);

    // ── Sincronização ────────────────────────────────────────────────

    List<Fornecedor> findBySyncStatusIn(List<String> statuses);

    @Query("""
        SELECT f FROM Fornecedor f
        WHERE f.updatedAt > :desde
    """)
    List<Fornecedor> findAtualizadosDepoisDe(@Param("desde") Instant desde);
}