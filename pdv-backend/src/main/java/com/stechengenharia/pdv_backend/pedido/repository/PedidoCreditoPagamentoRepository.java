package com.stechengenharia.pdv_backend.pedido.repository;

import com.stechengenharia.pdv_backend.pedido.entity.PedidoCreditoPagamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.math.BigDecimal;
import java.util.List;

public interface PedidoCreditoPagamentoRepository
        extends JpaRepository<PedidoCreditoPagamento, Long> {

    List<PedidoCreditoPagamento> findByPedido_IdPedidoOrderByDataPagamentoDesc(Integer idPedido);

    // usado pela sync local → cloud
    List<PedidoCreditoPagamento> findBySyncStatusIn(List<String> statuses);

    @Query("SELECT COALESCE(SUM(p.valorPago), 0) FROM PedidoCreditoPagamento p " +
           "WHERE p.pedido.idPedido = :idPedido AND p.deleted = false")
    BigDecimal somarPagosPorPedido(Integer idPedido);
}