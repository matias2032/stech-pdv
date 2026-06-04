package com.stechengenharia.pdv_backend.produto.repository;

import com.stechengenharia.pdv_backend.produto.entity.Produto;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface ProdutoRepository extends JpaRepository<Produto, Integer> {

    // ── Filtros safe (ignoram soft-deleted) ──────────────────────────
    List<Produto> findByDeletedFalse();

    List<Produto> findByAtivoAndDeletedFalse(Short ativo);

    Optional<Produto> findByIdProdutoAndDeletedFalse(Integer idProduto);

    // ── Sync ─────────────────────────────────────────────────────────
    List<Produto> findBySyncStatusIn(List<String> statuses);

    // ── Queries existentes — sem alterações ──────────────────────────
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Produto p SET p.quantidadeEstoque = p.quantidadeEstoque + :delta WHERE p.idProduto = :idProduto")
    void ajustarEstoque(@Param("idProduto") Integer idProduto, @Param("delta") int delta);

    @Query("""
        SELECT p.idProduto, p.nomeProduto, p.quantidadeEstoque, p.preco
        FROM Produto p
        WHERE p.ativo = 1
          AND p.deleted = false
          AND p.idProduto NOT IN (
              SELECT DISTINCT i.produto.idProduto
              FROM ItemPedido i
              WHERE i.pedido.dataPedido >= :dataInicio
                AND i.pedido.statusPedido NOT IN ('cancelado', 'por finalizar')
          )
        """)
    List<Object[]> produtosSemVendas(@Param("dataInicio") LocalDateTime dataInicio);
}