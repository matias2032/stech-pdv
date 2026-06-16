package com.stechengenharia.pdv_backend.pedido.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface CloudPagamentoCreditoRepository extends JpaRepository<CloudPagamentoCreditoEntity, Long> {

    List<CloudPagamentoCreditoEntity> findByUpdatedAtAfter(Instant since);

    List<CloudPagamentoCreditoEntity> findByIdPedidoOrderByDataPagamentoDesc(Integer idPedido);
}