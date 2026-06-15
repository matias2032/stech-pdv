package com.stechengenharia.pdv_backend.cotacao.repository;

import com.stechengenharia.pdv_backend.cotacao.entity.Cotacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface CotacaoRepository extends JpaRepository<Cotacao, Long> {

    // ── Busca por ID com itens e associações ──────────────────────────
    @Query("""
        SELECT c FROM Cotacao c
        LEFT JOIN FETCH c.cliente
        LEFT JOIN FETCH c.usuario
        LEFT JOIN FETCH c.itensProduto ip
        LEFT JOIN FETCH ip.produto
        LEFT JOIN FETCH c.itensServico is_
        LEFT JOIN FETCH is_.servico
        WHERE c.id = :id AND c.deleted = false
        """)
    Optional<Cotacao> findByIdCompleto(@Param("id") Long id);

    // ── Listagem geral (sem itens — evita N+1 na listagem) ────────────
    @Query("""
        SELECT c FROM Cotacao c
        LEFT JOIN FETCH c.cliente
        LEFT JOIN FETCH c.usuario
        WHERE c.deleted = false
        ORDER BY c.createdAt DESC
        """)
    List<Cotacao> findAllAtivas();

    // ── Filtro por status ─────────────────────────────────────────────
    @Query("""
        SELECT c FROM Cotacao c
        LEFT JOIN FETCH c.cliente
        LEFT JOIN FETCH c.usuario
        WHERE c.statusCotacao = :status AND c.deleted = false
        ORDER BY c.createdAt DESC
        """)
    List<Cotacao> findByStatus(@Param("status") String status);

    // ── Filtro por cliente ────────────────────────────────────────────
    @Query("""
        SELECT c FROM Cotacao c
        LEFT JOIN FETCH c.cliente
        LEFT JOIN FETCH c.usuario
        WHERE c.cliente.id = :idCliente AND c.deleted = false
        ORDER BY c.createdAt DESC
        """)
    List<Cotacao> findByClienteId(@Param("idCliente") Long idCliente);

    // ── Filtro por utilizador ─────────────────────────────────────────
    @Query("""
        SELECT c FROM Cotacao c
        LEFT JOIN FETCH c.cliente
        LEFT JOIN FETCH c.usuario
        WHERE c.usuario.id = :idUsuario AND c.deleted = false
        ORDER BY c.createdAt DESC
        """)
    List<Cotacao> findByUsuarioId(@Param("idUsuario") Long idUsuario);

    // ── Unicidade de referência ───────────────────────────────────────
    boolean existsByReferenciaAndDeletedFalse(String referencia);

    // ── Cotações expiradas ainda abertas (para job de expiração) ──────
    @Query("""
        SELECT c FROM Cotacao c
        WHERE c.validadeAte < :hoje
          AND c.statusCotacao NOT IN ('CONVERTIDA', 'CANCELADA', 'EXPIRADA')
          AND c.deleted = false
        """)
    List<Cotacao> findExpiradas(@Param("hoje") LocalDate hoje);

    @Query("""
    SELECT c FROM Cotacao c
    LEFT JOIN FETCH c.itensProduto
    LEFT JOIN FETCH c.itensServico
    LEFT JOIN FETCH c.cliente
    LEFT JOIN FETCH c.usuario
    WHERE c.statusCotacao = 'PRONTA'
    AND c.deleted = false
    ORDER BY c.createdAt DESC
    """)
List<Cotacao> findAllProntas();

    // ── Sincronização ─────────────────────────────────────────────────
    List<Cotacao> findBySyncStatusIn(List<String> statuses);

    @Query("SELECT c FROM Cotacao c WHERE c.updatedAt > :desde")
    List<Cotacao> findAtualizadasDepoisDe(@Param("desde") Instant desde);


}