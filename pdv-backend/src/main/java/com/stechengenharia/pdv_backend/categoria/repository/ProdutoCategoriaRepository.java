package com.stechengenharia.pdv_backend.categoria.repository;

import com.stechengenharia.pdv_backend.categoria.entity.ProdutoCategoria;
import com.stechengenharia.pdv_backend.categoria.entity.ProdutoCategoriaId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProdutoCategoriaRepository extends JpaRepository<ProdutoCategoria, ProdutoCategoriaId> {
    
    List<ProdutoCategoria> findByIdCategoria(Integer idCategoria);
    
    List<ProdutoCategoria> findByIdProduto(Integer idProduto);
    
    @Modifying
    @Query("DELETE FROM ProdutoCategoria pc WHERE pc.idCategoria = :idCategoria AND pc.idProduto = :idProduto")
    void deleteByIdCategoriaAndIdProduto(@Param("idCategoria") Integer idCategoria, @Param("idProduto") Integer idProduto);
    
    boolean existsByIdCategoriaAndIdProduto(Integer idCategoria, Integer idProduto);
}