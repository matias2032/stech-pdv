package com.stechengenharia.pdv_backend.despesa.repository;

import com.stechengenharia.pdv_backend.despesa.entity.Despesa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;

@Repository
public interface DespesaRepository extends JpaRepository<Despesa, Long> {

    List<Despesa> findByDeletedFalseOrderByDataDespesaDesc();

List<Despesa> findByFornecedor_IdAndDeletedFalseOrderByDataDespesaDesc(
        Long idFornecedor
);

    List<Despesa> findByDataDespesaBetweenAndDeletedFalseOrderByDataDespesaDesc(
            OffsetDateTime inicio,
            OffsetDateTime fim
    );

    List<Despesa> findBySyncStatusIn(List<String> statuses);
}