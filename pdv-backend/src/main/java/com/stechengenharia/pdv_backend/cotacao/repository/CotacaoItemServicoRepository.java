package com.stechengenharia.pdv_backend.cotacao.repository;

import com.stechengenharia.pdv_backend.cotacao.entity.CotacaoItemServico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CotacaoItemServicoRepository extends JpaRepository<CotacaoItemServico, Long> {

    // ── Busca item por ID garantindo que pertence à cotação ───────────
    @Query("""
        SELECT is_ FROM CotacaoItemServico is_
        JOIN FETCH is_.servico
        WHERE is_.id = :idItem AND is_.cotacao.id = :idCotacao
        """)
    Optional<CotacaoItemServico> findByIdECotacao(
            @Param("idItem") Long idItem,
            @Param("idCotacao") Long idCotacao);

    // ── Lista itens de uma cotação (com JOIN para o serviço) ──────────
    @Query("""
        SELECT is_ FROM CotacaoItemServico is_
        JOIN FETCH is_.servico
        WHERE is_.cotacao.id = :idCotacao
        """)
    List<CotacaoItemServico> findByCotacaoIdComServico(@Param("idCotacao") Long idCotacao);

    // ── Lista itens de uma cotação (simples — para sync) ──────────────
    @Query("SELECT is_ FROM CotacaoItemServico is_ WHERE is_.cotacao.id = :idCotacao")
    List<CotacaoItemServico> findByCotacaoId(@Param("idCotacao") Long idCotacao);

    // ── Verifica se serviço já existe na cotação (evita duplicados) ───
    Optional<CotacaoItemServico> findByCotacaoIdAndServicoIdServico(Long idCotacao, Integer idServico);
}