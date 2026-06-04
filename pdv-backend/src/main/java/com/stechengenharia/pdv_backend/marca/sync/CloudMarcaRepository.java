package com.stechengenharia.pdv_backend.marca.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;

@Repository
public interface CloudMarcaRepository extends JpaRepository<CloudMarcaEntity, Integer> {
    List<CloudMarcaEntity> findByUpdatedAtAfter(Instant since);
}