package com.stechengenharia.pdv_backend.fornecedor.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;

@Repository
public interface CloudFornecedorRepository extends JpaRepository<CloudFornecedorEntity, Long> {

    List<CloudFornecedorEntity> findByUpdatedAtAfter(Instant since);
}