package com.stechengenharia.pdv_backend.documento.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;

@Repository
public interface CloudDocumentoRepository extends JpaRepository<CloudDocumentoEntity, Integer> {
    List<CloudDocumentoEntity> findByUpdatedAtAfter(Instant since);
}