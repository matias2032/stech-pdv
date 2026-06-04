package com.stechengenharia.pdv_backend.produto.repository;

import com.stechengenharia.pdv_backend.produto.entity.ProdutoImagem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProdutoImagemRepository extends JpaRepository<ProdutoImagem, Integer> {
    
    List<ProdutoImagem> findByIdProduto(Integer idProduto);
    
    // ✅ MUDANÇA: Integer → Short
    Optional<ProdutoImagem> findByIdProdutoAndImagemPrincipal(Integer idProduto, Short imagemPrincipal);
    
    @Modifying
    @Query("UPDATE ProdutoImagem pi SET pi.imagemPrincipal = 0 WHERE pi.idProduto = :idProduto")
    void desmarcarTodasImagensPrincipais(@Param("idProduto") Integer idProduto);
    
    @Modifying
    @Query("DELETE FROM ProdutoImagem pi WHERE pi.idProduto = :idProduto")
    void deleteByIdProduto(@Param("idProduto") Integer idProduto);
}