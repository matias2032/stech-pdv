package com.stechengenharia.pdv_backend.documento.repository;

import com.stechengenharia.pdv_backend.documento.entity.TipoDocumentoFiscal;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface TipoDocumentoFiscalRepository extends JpaRepository<TipoDocumentoFiscal, Integer> {

    Optional<TipoDocumentoFiscal> findByCodigo(String codigo);

    boolean existsByCodigo(String codigo);
}