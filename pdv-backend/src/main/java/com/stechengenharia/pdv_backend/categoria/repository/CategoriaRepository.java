package com.stechengenharia.pdv_backend.categoria.repository;

import com.stechengenharia.pdv_backend.categoria.entity.Categoria;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

import java.util.Optional;

@Repository
public interface CategoriaRepository extends JpaRepository<Categoria, Integer> {

    List<Categoria> findByDeletedFalse();

    Optional<Categoria> findByIdCategoriaAndDeletedFalse(Integer idCategoria);

    Optional<Categoria> findByNomeCategoriaAndDeletedFalse(String nomeCategoria);

    List<Categoria> findBySyncStatusIn(List<String> statuses);
}

