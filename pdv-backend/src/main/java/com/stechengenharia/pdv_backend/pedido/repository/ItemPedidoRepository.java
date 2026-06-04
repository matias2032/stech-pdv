package com.stechengenharia.pdv_backend.pedido.repository;

import com.stechengenharia.pdv_backend.pedido.entity.ItemPedido;
// import com.stechengenharia.pdv_backend.pedido.entity.Pedido;
// import com.stechengenharia.pdv_backend.pedido.entity.PedidoCancelamento;
import org.springframework.data.jpa.repository.JpaRepository;
// import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
@Repository
public interface ItemPedidoRepository extends JpaRepository<ItemPedido, Integer> {

    List<ItemPedido> findByPedidoIdPedido(Integer idPedido);

    Optional<ItemPedido> findByIdItemPedidoAndPedidoIdPedido(Integer idItem, Integer idPedido);

    /**
     * Retorna a quantidade total já reservada de um produto
     * em pedidos activos (não cancelados, não finalizados).
     * Útil para verificações de estoque em cenários concorrentes.
     */
    @Query("""
        SELECT COALESCE(SUM(i.quantidade), 0)
        FROM ItemPedido i
        WHERE i.produto.idProduto = :idProduto
          AND i.pedido.statusPedido NOT IN ('cancelado', 'finalizado')
          AND i.pedido.idPedido <> :idPedidoExcluir
        """)
    Integer totalReservadoParaProduto(
        @Param("idProduto") Integer idProduto,
        @Param("idPedidoExcluir") Integer idPedidoExcluir
    );

    // Top N produtos mais vendidos
@Query("""
    SELECT pr.nomeProduto, SUM(i.quantidade), SUM(i.subtotal), COUNT(DISTINCT i.pedido.idPedido)
    FROM ItemPedido i
    JOIN i.produto pr
    JOIN i.pedido p
    WHERE p.dataPedido >= :dataInicio
      AND p.statusPedido NOT IN ('cancelado', 'por finalizar')
    GROUP BY pr.idProduto, pr.nomeProduto
    ORDER BY SUM(i.quantidade) DESC
    LIMIT 5
    """)
List<Object[]> top5Produtos(@Param("dataInicio") LocalDateTime dataInicio);

// Vendas por categoria
@Query("""
    SELECT c.nomeCategoria, SUM(i.subtotal)
    FROM ItemPedido i
    JOIN i.produto pr
    JOIN i.pedido p
    JOIN ProdutoCategoria pc ON pc.idProduto = pr.idProduto
    JOIN Categoria c ON c.idCategoria = pc.idCategoria
    WHERE p.dataPedido >= :dataInicio
      AND p.statusPedido NOT IN ('cancelado', 'por finalizar')
    GROUP BY c.idCategoria, c.nomeCategoria
    ORDER BY SUM(i.subtotal) DESC
    """)
List<Object[]> vendasPorCategoria(@Param("dataInicio") LocalDateTime dataInicio);

// Vendas por marca
@Query("""
    SELECT m.nomeMarca, SUM(i.subtotal)
    FROM ItemPedido i
    JOIN i.produto pr
    JOIN i.pedido p
    JOIN ProdutoMarca pm ON pm.idProduto = pr.idProduto
    JOIN Marca m ON m.idMarca = pm.idMarca
    WHERE p.dataPedido >= :dataInicio
      AND p.statusPedido NOT IN ('cancelado', 'por finalizar')
    GROUP BY m.idMarca, m.nomeMarca
    ORDER BY SUM(i.subtotal) DESC
    """)
List<Object[]> vendasPorMarca(@Param("dataInicio") LocalDateTime dataInicio);
}

