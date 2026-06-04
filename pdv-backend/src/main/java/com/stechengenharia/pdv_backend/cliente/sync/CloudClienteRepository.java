package com.stechengenharia.pdv_backend.cliente.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;

@Repository
public interface CloudClienteRepository extends JpaRepository<CloudClienteEntity, Long> {
    List<CloudClienteEntity> findByUpdatedAtAfter(Instant since);
}