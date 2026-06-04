package com.stechengenharia.pdv_backend.produto.repository;

import com.stechengenharia.pdv_backend.produto.entity.ProdutoMarca;
import com.stechengenharia.pdv_backend.produto.entity.ProdutoMarcaId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProdutoMarcaRepository extends JpaRepository<ProdutoMarca, ProdutoMarcaId> {
    
    List<ProdutoMarca> findByIdMarca(Integer idMarca);
    
    List<ProdutoMarca> findByIdProduto(Integer idProduto);
    
    @Modifying
    @Query("DELETE FROM ProdutoMarca pm WHERE pm.idMarca = :idMarca AND pm.idProduto = :idProduto")
    void deleteByIdMarcaAndIdProduto(@Param("idMarca") Integer idMarca, @Param("idProduto") Integer idProduto);
    
    boolean existsByIdMarcaAndIdProduto(Integer idMarca, Integer idProduto);
}