package com.stechengenharia.pdv_backend.pedido.repository;

import com.stechengenharia.pdv_backend.pedido.entity.Pedido;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface PedidoRepository extends JpaRepository<Pedido, Integer> {

    Optional<Pedido> findByReferencia(String referencia);

    List<Pedido> findByIdUsuarioOrderByDataPedidoDesc(Integer idUsuario);

    List<Pedido> findByStatusPedidoOrderByDataPedidoDesc(String statusPedido);

    List<Pedido> findByIdUsuarioAndStatusPedidoOrderByDataPedidoDesc(
            Integer idUsuario, String statusPedido);

            // Adicionar ao PedidoRepository existente:

// ── Soft delete ───────────────────────────────────────────────────────
List<Pedido> findByDeletedFalse();

Optional<Pedido> findByIdPedidoAndDeletedFalse(Integer idPedido);

// ── Sync ──────────────────────────────────────────────────────────────
List<Pedido> findBySyncStatusIn(List<String> statuses);

// ── Queries existentes com filtro deleted adicionado ─────────────────
// (substituir as versões sem filtro nas queries de status)
List<Pedido> findByStatusPedidoAndDeletedFalseOrderByDataPedidoDesc(String statusPedido);

List<Pedido> findByIdUsuarioAndDeletedFalseOrderByDataPedidoDesc(Integer idUsuario);

@Query("""
    SELECT DISTINCT p
    FROM Pedido p
    LEFT JOIN FETCH p.itensProduto ip
    LEFT JOIN FETCH ip.produto
    LEFT JOIN FETCH p.itensServico isv
    LEFT JOIN FETCH isv.servico
    WHERE p.idPedido = :idPedido
      AND p.deleted = false
""")
Optional<Pedido> findByIdComItens(@Param("idPedido") Integer idPedido);

    // ─── Evolução de vendas por dia ──────────────────────────────────────────

    @Query("""
        SELECT CAST(p.dataPedido AS date), SUM(p.total)
        FROM Pedido p
        WHERE p.dataPedido >= :dataInicio
          AND p.statusPedido NOT IN ('cancelado')
        GROUP BY CAST(p.dataPedido AS date)
        ORDER BY CAST(p.dataPedido AS date)
        """)
    List<Object[]> evolucaoVendasPorDia(@Param("dataInicio") LocalDateTime dataInicio);

    // ─── Relatório por utilizador ────────────────────────────────────────────

    @Query("""
        SELECT CAST(p.dataPedido AS date), COUNT(p.idPedido)
        FROM Pedido p
        WHERE p.idUsuario = :idUsuario
          AND p.dataPedido >= :dataInicio
        GROUP BY CAST(p.dataPedido AS date)
        HAVING COUNT(p.idPedido) > 0
        ORDER BY CAST(p.dataPedido AS date)
        """)
    List<Object[]> evolucaoPedidosPorUsuario(
            @Param("idUsuario") Integer idUsuario,
            @Param("dataInicio") LocalDateTime dataInicio);

    @Query("SELECT COUNT(p) FROM Pedido p WHERE p.idUsuario = :idUsuario AND p.dataPedido >= :dataInicio")
    long totalPedidosPorUsuario(
            @Param("idUsuario") Integer idUsuario,
            @Param("dataInicio") LocalDateTime dataInicio);

    @Query("""
        SELECT CAST(p.dataPedido AS date), SUM(p.total)
        FROM Pedido p
        WHERE p.idUsuario = :idUsuario
          AND p.dataPedido >= :dataInicio
        GROUP BY CAST(p.dataPedido AS date)
        ORDER BY CAST(p.dataPedido AS date)
        """)
    List<Object[]> evolucaoVendasPorUsuario(
            @Param("idUsuario") Integer idUsuario,
            @Param("dataInicio") LocalDateTime dataInicio);

    @Query("SELECT COALESCE(SUM(p.total), 0) FROM Pedido p WHERE p.idUsuario = :idUsuario AND p.dataPedido >= :dataInicio")
    BigDecimal totalVendasPorUsuario(
            @Param("idUsuario") Integer idUsuario,
            @Param("dataInicio") LocalDateTime dataInicio);

       @Query("""
    SELECT COUNT(p)
    FROM Pedido p
    WHERE p.statusPedido = 'aberto'
      AND p.deleted = false
""")
long contarPedidosAbertos();

            List<Pedido> findByIdClienteAndTipoVendaAndDeletedFalse(Long idCliente, String tipoVenda);
            List<Pedido> findByTipoVendaAndDeletedFalseOrderByDataPedidoDesc(String tipoVenda);
}