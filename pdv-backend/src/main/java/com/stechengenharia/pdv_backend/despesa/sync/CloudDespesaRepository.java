package com.stechengenharia.pdv_backend.despesa.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface CloudDespesaRepository extends JpaRepository<CloudDespesaEntity, Long> {

    List<CloudDespesaEntity> findByUpdatedAtAfter(Instant since);
}