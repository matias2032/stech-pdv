package com.stechengenharia.pdv_backend.categoria.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.util.Objects;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ProdutoCategoriaId implements Serializable {
    
    private Integer idProduto;
    private Integer idCategoria;
    
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        ProdutoCategoriaId that = (ProdutoCategoriaId) o;
        return Objects.equals(idProduto, that.idProduto) && 
               Objects.equals(idCategoria, that.idCategoria);
    }
    
    @Override
    public int hashCode() {
        return Objects.hash(idProduto, idCategoria);
    }
}