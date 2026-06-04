package com.stechengenharia.pdv_backend.pedido.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;

@Repository
public interface CloudPedidoRepository extends JpaRepository<CloudPedidoEntity, Integer> {
    List<CloudPedidoEntity> findByUpdatedAtAfter(Instant since);
}