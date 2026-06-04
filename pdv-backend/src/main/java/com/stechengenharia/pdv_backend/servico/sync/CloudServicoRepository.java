package com.stechengenharia.pdv_backend.servico.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;

@Repository
public interface CloudServicoRepository extends JpaRepository<CloudServicoEntity, Integer> {
    List<CloudServicoEntity> findByUpdatedAtAfter(Instant since);
}