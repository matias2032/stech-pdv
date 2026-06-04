package com.stechengenharia.pdv_backend.marca.repository;

import com.stechengenharia.pdv_backend.categoria.entity.CategoriaMarca;
import com.stechengenharia.pdv_backend.marca.entity.Marca;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.List;

@Repository
public interface MarcaRepository extends JpaRepository<Marca, Integer> {

    // Substitui o findAll() padrão — ignora soft-deleted
    List<Marca> findByDeletedFalse();

    // Para o findById seguro
    Optional<Marca> findByIdMarcaAndDeletedFalse(Integer idMarca);

    Optional<Marca> findByNomeMarcaAndDeletedFalse(String nomeMarca);

    // Para o SyncService
    List<Marca> findBySyncStatusIn(List<String> statuses);
}

