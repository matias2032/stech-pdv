package com.stechengenharia.pdv_backend.categoria.repository;

import com.stechengenharia.pdv_backend.categoria.entity.CategoriaMarca;
import com.stechengenharia.pdv_backend.categoria.entity.CategoriaMarcaId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CategoriaMarcaRepository extends JpaRepository<CategoriaMarca, CategoriaMarcaId> {
    
    List<CategoriaMarca> findByIdCategoria(Integer idCategoria);
    
    List<CategoriaMarca> findByIdMarca(Integer idMarca);
    
    @Modifying
    @Query("DELETE FROM CategoriaMarca cm WHERE cm.idCategoria = :idCategoria AND cm.idMarca = :idMarca")
    void deleteByIdCategoriaAndIdMarca(@Param("idCategoria") Integer idCategoria, @Param("idMarca") Integer idMarca);
    
    boolean existsByIdCategoriaAndIdMarca(Integer idCategoria, Integer idMarca);
}