package com.stechengenharia.pdv_backend.categoria.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;

@Repository
public interface CloudCategoriaRepository extends JpaRepository<CloudCategoriaEntity, Integer> {

    // Corrige o erro "findByUpdatedAtAfter is undefined"
    List<CloudCategoriaEntity> findByUpdatedAtAfter(Instant since);
}