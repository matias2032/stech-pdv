package com.stechengenharia.pdv_backend.pedido.repository;

import com.stechengenharia.pdv_backend.pedido.entity.PedidoCreditoParcela;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface PedidoCreditoParcelaRepository
        extends JpaRepository<PedidoCreditoParcela, Long> {

    List<PedidoCreditoParcela> findByPedido_IdPedidoOrderByNumeroParcela(Integer idPedido);

    Optional<PedidoCreditoParcela> findByIdParcelaAndPedido_IdPedido(
            Long idParcela, Integer idPedido);

    List<PedidoCreditoParcela> findByPedido_IdPedidoAndStatusParcela(
            Integer idPedido, String status);

    // usado pela sync local → cloud
    List<PedidoCreditoParcela> findBySyncStatusIn(List<String> statuses);
}