package com.stechengenharia.pdv_backend.pedido.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface CloudParcelaRepository extends JpaRepository<CloudParcelaEntity, Long> {

    List<CloudParcelaEntity> findByUpdatedAtAfter(Instant since);

    List<CloudParcelaEntity> findByIdPedidoOrderByNumeroParcela(Integer idPedido);
}