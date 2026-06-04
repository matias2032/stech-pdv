package com.stechengenharia.pdv_backend.produto.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;

@Repository
public interface CloudProdutoRepository extends JpaRepository<CloudProdutoEntity, Integer> {
    List<CloudProdutoEntity> findByUpdatedAtAfter(Instant since);
}