package com.stechengenharia.pdv_backend.despesa.repository;

import com.stechengenharia.pdv_backend.despesa.entity.TipoDespesa;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TipoDespesaRepository extends JpaRepository<TipoDespesa, Long> {

    List<TipoDespesa> findByDeletedFalseOrderByNomeDespesaAsc();

    List<TipoDespesa> findBySyncStatusIn(List<String> statuses);
}