package com.stechengenharia.pdv_backend.cotacao.repository;

import com.stechengenharia.pdv_backend.cotacao.entity.CotacaoItemProduto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CotacaoItemProdutoRepository extends JpaRepository<CotacaoItemProduto, Long> {

    // ── Busca item por ID garantindo que pertence à cotação ───────────
    @Query("""
        SELECT ip FROM CotacaoItemProduto ip
        JOIN FETCH ip.produto
        WHERE ip.id = :idItem AND ip.cotacao.id = :idCotacao
        """)
    Optional<CotacaoItemProduto> findByIdECotacao(
            @Param("idItem") Long idItem,
            @Param("idCotacao") Long idCotacao);

    // ── Lista itens de uma cotação (com JOIN para o produto) ──────────
    @Query("""
        SELECT ip FROM CotacaoItemProduto ip
        JOIN FETCH ip.produto
        WHERE ip.cotacao.id = :idCotacao
        """)
    List<CotacaoItemProduto> findByCotacaoIdComProduto(@Param("idCotacao") Long idCotacao);

    // ── Lista itens de uma cotação (simples — para sync) ──────────────
    @Query("SELECT ip FROM CotacaoItemProduto ip WHERE ip.cotacao.id = :idCotacao")
    List<CotacaoItemProduto> findByCotacaoId(@Param("idCotacao") Long idCotacao);

    // ── Verifica se produto já existe na cotação (evita duplicados) ───
    Optional<CotacaoItemProduto> findByCotacaoIdAndProdutoIdProduto(Long idCotacao, Integer idProduto);
}