package com.stechengenharia.pdv_backend.cotacao.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface CloudCotacaoRepository extends JpaRepository<CloudCotacaoEntity, Long> {
    List<CloudCotacaoEntity> findByUpdatedAtAfter(Instant since);
}